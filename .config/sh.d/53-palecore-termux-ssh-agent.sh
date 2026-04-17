# connect to ssh-agent in termux-specific subdirectory if applicable:
if [ -S "${PREFIX-}/var/run/ssh-agent.socket" ]; then
    export SSH_AUTH_SOCK="${PREFIX-}/var/run/ssh-agent.socket"
fi
