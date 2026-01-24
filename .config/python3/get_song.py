"""
Download music files from URLs using yt-dlp.
"""

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
from collections import deque
from datetime import datetime
from pathlib import Path
from typing import List, Optional


class UtilityRegistry:
    """Cache checker for termux command availability."""
    _cache: dict[str, bool] = {}

    def is_available(self, command: str) -> bool:
        """Check if a command is available in PATH, with caching."""
        if command not in self._cache:
            self._cache[command] = shutil.which(command) is not None
        return self._cache[command]


# global instance of utility registry:
utility_reg = UtilityRegistry()

# convenience function to separate usage from the class:
is_available = utility_reg.is_available


class TermuxNotificationLogger:
    """
    Logger that renders logs to Android notifications via termux-notification.
    Keeps a circular buffer of recent messages and all messages for full log view.
    """

    def __init__(self, prog_name: str, max_recent: int = 5):
        """
        Initialize the notification logger.

        Args:
            prog_name: Program name used as notification ID and title
            max_recent: Maximum number of recent lines to show in notification
        """
        self.prog_name = prog_name
        self.prog_label = prog_name.replace('-', ' ')
        self.max_recent = max_recent
        self.recent_msgs = deque(maxlen=max_recent)
        self.all_msgs: List[str] = []

    def _escape_shell_arg(self, text: str) -> str:
        """Escape text for safe shell argument passing."""
        return shlex.quote(text)

    def _build_show_all_logs_cmd(self) -> str:
        """Build the command to show all logs in a dialog."""
        content = '\n'.join(self.all_msgs)
        cmd_parts = [
            'termux-dialog', 'confirm', '-t',
            self._escape_shell_arg(f"{self.prog_label} - All Logs"), '-i',
            self._escape_shell_arg(content)
        ]
        return ' '.join(cmd_parts)

    def _show_notification(self, ongoing: bool = True) -> None:
        """Show or update the notification with recent messages."""
        if not self.recent_msgs:
            return

        content = '\n'.join(self.recent_msgs)

        cmd = [
            'termux-notification', '--alert-once', '--action',
            self._build_show_all_logs_cmd(), '--id', self.prog_name, '--title',
            self.prog_label, '--content', content
        ]

        if ongoing:
            cmd.insert(1, '--ongoing')

        try:
            subprocess.run(cmd, capture_output=True, check=False)
        except FileNotFoundError:
            pass

    def log(self, message: str) -> None:
        """Add a log message and update the notification."""
        # if the recent_msgs deque is full, remove the oldest message:
        if len(self.recent_msgs) == self.recent_msgs.maxlen:
            self.recent_msgs.popleft()
        self.recent_msgs.append(message)
        self.all_msgs.append(message)
        self._show_notification(ongoing=True)

    def finalize(self) -> None:
        """Show final notification (not ongoing) with all accumulated logs."""
        if self.all_msgs:
            self._show_notification(ongoing=False)


# Global logger instance
_logger: Optional[TermuxNotificationLogger] = None


def init_logger(prog_name: str = 'get-song', max_recent: int = 5) -> None:
    """Initialize the global notification logger."""
    global _logger
    _logger = TermuxNotificationLogger(prog_name, max_recent)


def get_logger() -> Optional[TermuxNotificationLogger]:
    """Get the global notification logger instance."""
    return _logger


def tell_debug(message: str) -> None:
    """Print a debug message to stderr."""
    full_msg = f"DEBUG: {message}"
    print(full_msg, file=sys.stderr)
    logger = get_logger()
    if logger:
        logger.log(full_msg)


def tell_info(message: str) -> None:
    """Print an info message to stderr."""
    full_msg = f"INFO: {message}"
    print(full_msg, file=sys.stderr)
    logger = get_logger()
    if logger:
        logger.log(full_msg)


def tell_warn(message: str) -> None:
    """Print a warning message to stderr."""
    full_msg = f"WARN: {message}"
    print(full_msg, file=sys.stderr)
    logger = get_logger()
    if logger:
        logger.log(full_msg)


def tell_error(message: str) -> None:
    """Print an error message to stderr."""
    full_msg = f"ERROR: {message}"
    print(full_msg, file=sys.stderr)
    logger = get_logger()
    if logger:
        logger.log(full_msg)


def run_termux_toast(message: str,
                     background_color: str = 'green',
                     text_color: str = 'black',
                     position: str = 'bottom') -> None:
    """Show a Termux toast notification (if possible)."""
    if is_available('termux-toast'):
        cmd = [
            'termux-toast', '-b', background_color, '-c', text_color, '-g',
            position, message
        ]
        subprocess.run(cmd, capture_output=True, check=False)


def tell_success(message: str) -> None:
    """Print a success message to stderr and show a Termux success toast."""
    tell_info(message=message)
    # send a Termux toast:
    run_termux_toast(message=message,
                     background_color='green',
                     text_color='black',
                     position='bottom')


def tell_failure(message: str) -> None:
    """Print a failure message to stderr and show a Termux failure toast."""
    tell_error(message=message)
    # send a Termux toast:
    run_termux_toast(message=message,
                     background_color='red',
                     text_color='black',
                     position='bottom')


def tell_warn_toast(message: str) -> None:
    """Print a warning message to stderr and show a Termux warning toast."""
    tell_warn(message=message)
    # send a Termux toast:
    run_termux_toast(message=message,
                     background_color='orange',
                     text_color='black',
                     position='bottom')


def check_dependencies() -> bool:
    """Check if required dependencies are available."""
    dependencies = ['yt-dlp']
    missing = []

    for dep in dependencies:
        if not is_available(dep):
            missing.append(dep)

    if missing:
        print(f"ERROR: Required utilities missing: {', '.join(missing)}",
              file=sys.stderr)
        return False
    return True


def populate_empty_album_with_title(filepath: Path) -> bool:
    """
    Populate empty album metadata field with the title field.
    Uses a fallback chain: mutagen -> ffmpeg -> warn user.

    Args:
        filepath: Path to the audio file

    Returns:
        True if successful or album was already populated, False if failed
    """
    # Try mutagen first
    try:
        from mutagen import File as MutagenFile  # type: ignore[attr-defined]

        tell_debug("Using mutagen to check and populate album metadata...")
        audio = MutagenFile(filepath)

        if audio is None:
            tell_warn(f"Could not read audio file: {filepath.name}")
            return False

        # Handle different file formats
        album = None
        title = None

        # For Opus/Ogg Vorbis files
        if hasattr(audio, 'tags') and audio.tags:
            album = audio.tags.get(
                'album', [None])[0] if 'album' in audio.tags else None
            title = audio.tags.get(
                'title', [None])[0] if 'title' in audio.tags else None

            if not album or album.strip() == '':
                if title and title.strip() != '':
                    audio.tags['album'] = title
                    audio.save()
                    tell_info(f"Populated empty album with title: {title}")
                    return True
                else:
                    tell_debug("Title is also empty, cannot populate album")
                    return True
            else:
                tell_debug(f"Album already populated: {album}")
                return True

        tell_debug("No tags found in audio file")
        return True

    except ImportError:
        tell_debug("mutagen library not available, trying ffmpeg...")

        # Try ffmpeg as fallback
        if is_available('ffmpeg'):
            tell_debug("Using ffmpeg to check and populate album metadata...")

            # First, probe the file to get current metadata
            probe_cmd = [
                'ffprobe', '-v', 'quiet', '-print_format', 'json',
                '-show_format',
                str(filepath)
            ]

            try:
                probe_result = subprocess.run(probe_cmd,
                                              capture_output=True,
                                              text=True,
                                              check=True)

                metadata = json.loads(probe_result.stdout)
                tags = metadata.get('format', {}).get('tags', {})

                # Handle case-insensitive tag names
                album = tags.get('album') or tags.get('ALBUM')
                title = tags.get('title') or tags.get('TITLE')

                if not album or album.strip() == '':
                    if title and title.strip() != '':
                        # Use ffmpeg to copy the file with updated metadata
                        temp_output = filepath.with_suffix(filepath.suffix +
                                                           '.tmp')
                        ffmpeg_cmd = [
                            'ffmpeg', '-i',
                            str(filepath), '-c', 'copy', '-metadata',
                            f'album={title}',
                            str(temp_output), '-y', '-v', 'quiet'
                        ]

                        result = subprocess.run(ffmpeg_cmd,
                                                capture_output=True,
                                                text=True)

                        if result.returncode == 0:
                            # Replace original file with updated one
                            temp_output.replace(filepath)
                            tell_info(
                                f"Populated empty album with title: {title}")
                            return True
                        else:
                            tell_warn(
                                f"ffmpeg failed to update metadata: {result.stderr}"
                            )
                            if temp_output.exists():
                                temp_output.unlink()
                            return False
                    else:
                        tell_debug(
                            "Title is also empty, cannot populate album")
                        return True
                else:
                    tell_debug(f"Album already populated: {album}")
                    return True

            except subprocess.CalledProcessError as e:
                tell_warn(f"ffprobe failed: {e}")
                return False
            except json.JSONDecodeError as e:
                tell_warn(f"Failed to parse ffprobe output: {e}")
                return False
            except Exception as e:
                tell_warn(f"Error using ffmpeg: {e}")
                return False
        else:
            # Neither mutagen nor ffmpeg available
            msg = "Cannot populate album: neither mutagen library nor ffmpeg utility available"
            tell_warn_toast(msg)
            return False

    except Exception as e:
        tell_warn(f"Error populating album metadata: {e}")
        return False


def transform_filename(filepath: str) -> str:
    """
    Transform filename according to the rules:
    - Map % to %prcnt
    - Replace _ with - (whitespace)
    - Replace -- with _ (double dash)
    - Make lowercase
    """
    new_filepath = filepath

    # Temporarily map replacements to percent-prefixed phrases
    new_filepath = new_filepath.replace('%', '%prcnt')
    # For whitespace, yt-dlp uses underscores. Replace them with dashes
    new_filepath = new_filepath.replace('_', '%whspc')
    new_filepath = new_filepath.replace('--', '%ddash')
    # Resolve percent-prefixed phrases
    new_filepath = new_filepath.replace('%whspc', '-')
    new_filepath = new_filepath.replace('%ddash', '_')
    new_filepath = new_filepath.replace('%prcnt', '%')
    # Make the whole filename lowercase
    new_filepath = new_filepath.lower()

    return new_filepath


def download_song(url: str,
                  target_dir: Path,
                  timestamp: Optional[str] = None,
                  populate_album: bool = False) -> Optional[Path]:
    """
    Download a single song from the given URL.

    Args:
        url: The URL to download from
        target_dir: Directory to save the file to
        timestamp: Optional timestamp prefix for filename
        populate_album: If True, populate empty album metadata with title

    Returns:
        Path to the downloaded file if successful, None otherwise
    """
    if timestamp is None:
        timestamp = datetime.now().strftime('%Y%m%d')

    # Create temporary file for filepath output
    with tempfile.NamedTemporaryFile(mode='w+',
                                     delete=False,
                                     prefix='yt-dlp-filepath-') as tmp:
        filepath_tmpfile = tmp.name

    try:
        # Construct output template
        output_template = (
            f"{timestamp}--%(artist,album_artist,channel|unknown)#S--"
            f"%(album|unknown)#S--%(track,title|unknown)#S.%(ext)#S")

        tell_info("Downloading the file...")

        # Run yt-dlp
        cmd = [
            'yt-dlp', '--no-playlist', '--js-runtimes', 'node',
            '--audio-format', 'opus', '-x', '--embed-metadata',
            '--embed-thumbnail', '--embed-subs', '-o', output_template,
            '--print-to-file', 'after_move:filepath', filepath_tmpfile, '--',
            url
        ]

        result = subprocess.run(
            cmd,
            cwd=target_dir,
            capture_output=False,
            text=True,
        )

        if result.returncode != 0:
            return None

        # Read the filepath from temp file
        with open(filepath_tmpfile, 'r') as f:
            filepath = f.read().strip()

        if not filepath:
            tell_error("No filepath returned from yt-dlp!")
            return None

        # Transform filename
        new_filepath = transform_filename(filepath)

        if filepath != new_filepath:
            tell_info("Tweaking the file name...")
            old_path = target_dir / filepath
            new_path = target_dir / new_filepath

            if old_path.exists():
                old_path.rename(new_path)
                tell_info(f"Renamed '{old_path.name}' to '{new_path.name}'.")
                filepath = new_filepath
            else:
                tell_warn(f"File '{filepath}' not found, skipping rename...")

        # Touch the file to update timestamp
        final_path = target_dir / filepath
        if final_path.exists():
            final_path.touch()

        # Populate empty album with title if requested
        if populate_album:
            tell_info("Checking album metadata...")
            populate_empty_album_with_title(final_path)

        tell_info("Done.")
        return final_path

    except Exception as e:
        tell_error(str(e))
        return None
    finally:
        # Clean up temp file
        try:
            os.unlink(filepath_tmpfile)
        except:
            tell_warn(f"Deleting temp file '{filepath_tmpfile}' failed.")


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Downloads music files for given URLs using yt-dlp.',
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        '-d',
        '--directory',
        metavar='DIR',
        default=os.getcwd(),
        help='Directory to save downloaded files (default: current directory)')
    parser.add_argument(
        '-t',
        '--timestamp',
        metavar='DATETIME',
        help=
        f'Timestamp prefix for filenames (default: {datetime.now().strftime("%Y%m%d")})'
    )
    parser.add_argument(
        '--notification-lines',
        metavar='N',
        type=int,
        default=5,
        help='Number of recent log lines to show in notification (default: 5)')
    parser.add_argument(
        '--populate-empty-album',
        action='store_true',
        help='Populate empty album metadata field with the title field')
    parser.add_argument('urls',
                        metavar='URL',
                        nargs='+',
                        help='URLs to download from')

    args = parser.parse_args()

    # Initialize the notification logger
    init_logger(prog_name='get-song', max_recent=args.notification_lines)

    # Check dependencies
    if not check_dependencies():
        logger = get_logger()
        if logger:
            logger.finalize()
        return 1

    # Convert target directory to Path and ensure it exists
    target_dir = Path(args.directory).resolve()
    if not target_dir.exists():
        print(f"ERROR: Directory does not exist: {target_dir}",
              file=sys.stderr)
        logger = get_logger()
        if logger:
            logger.finalize()
        return 1

    if not target_dir.is_dir():
        print(f"ERROR: Not a directory: {target_dir}", file=sys.stderr)
        logger = get_logger()
        if logger:
            logger.finalize()
        return 1

    # Download each URL
    all_success = True
    downloaded_files = []
    for url in args.urls:
        tell_info(f"Processing URL '{url}'...")
        downloaded_file = download_song(url, target_dir, args.timestamp,
                                        args.populate_empty_album)
        if downloaded_file:
            downloaded_files.append(downloaded_file)
        else:
            all_success = False
            tell_warn(f"Failed to download '{url}'!")

    # Run termux-media-scan on downloaded files
    if downloaded_files:
        tell_info("Scanning files for Android media library...")
        for file_path in downloaded_files:
            try:
                result = subprocess.run(
                    ['termux-media-scan', '-v',
                     str(file_path)],
                    capture_output=True,
                    text=True)
                if result.returncode == 0:
                    tell_info(f"Media scan completed for '{file_path.name}'")
                else:
                    tell_warn(f"Media scan failed for '{file_path.name}'")
            except FileNotFoundError:
                tell_warn("termux-media-scan not found, skipping media scan")
                break
            except Exception as e:
                tell_warn(f"Media scan error for '{file_path.name}': {e}")

    if all_success:
        tell_success("Song(s) downloaded successfully.")
        result_code = 0
    else:
        tell_failure("Failed to download some songs!")
        result_code = 1

    # Finalize the notification (make it non-ongoing)
    logger = get_logger()
    if logger:
        logger.finalize()

    return result_code


if __name__ == '__main__':
    sys.exit(main())
