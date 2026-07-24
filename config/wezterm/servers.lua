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
		remote_address = "morgan-v4",
		username = "ubuntu",
	},
	{
		name = "pi",
		remote_address = "192.168.1.243",
		username = "pi",
	},
}

return M
