# @author Johannes Knoedtel
# This Module is intended to provide utility functions for working with SSH.
# Currently it only supports functions related to +ssh-agent+
module SSHUtil
  # Starts a +ssh-agent+.
  # It sets the environment accoring to the output of the +ssh-agent+ command.
  def SSHUtil.start_agent()
    vars = `ssh-agent`
    ssh_auth_sock = vars.scan(/SSH_AUTH_SOCK=([^;]+)/)[0][0]
    ssh_agent_pid = vars.scan(/SSH_AGENT_PID=(\d+)/)[0][0]
    ENV["SSH_AUTH_SOCK"] = ssh_auth_sock
    ENV["SSH_AGENT_PID"] = ssh_agent_pid
    raise RuntimeError, "couldn't start ssh-agent" unless $?.success?
  end

  # Adds a key to a running +ssh-agent+
  # @param filename [String] Filename of the key to be added.
  # @param ssh_askpass [String] Path of the executable to be used for password entry.
  def SSHUtil.add_key(filename, ssh_askpass = "/usr/lib/ssh/x11-ssh-askpass")
    ENV["SSH_ASKPASS"] = ssh_askpass
    if ENV["SSH_AGENT_PID"].nil? then
      raise RuntimeError, "no agent started yet"
    end
    system "ssh-add #{filename} < /dev/null"
    raise RuntimeError, "couldn't add key #{filename}" unless $?.success?
  end
end
