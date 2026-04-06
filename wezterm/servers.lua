local M = {}

M.ssh_domains = {
	{
		name = "home-lab",
		remote_address = "192.168.1.244",
		username = "morgan",
	},
	{
		name = "desktop-server",
		remote_address = "192.168.1.245",
		username = "morgan",
	},
	{
		name = "devenv_work",
		remote_address = "devenv",
		username = "ubuntu",
		ssh_option = {
			identityfile = "~/.cache/atlassian/remote-dev-env/ssh/id_rsa_rde",
			stricthostkeychecking = "no",
			userknownhostsfile = "/dev/null",
		},
	},
}

return M
