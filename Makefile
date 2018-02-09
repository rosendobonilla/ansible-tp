# vim: ft=make syn=make fileencoding=utf-8 sw=2 ts=2 ai eol et si
#
# Makefile: ASRALL 2018 Ansible Practice Boilerplate
#
# (c) 2018 Laurent Vallar <val@zbla.net>

ssh_opts = $(shell vagrant ssh-config | awk '/^  / { printf " -o "$$1"="$$2; }')
ops_ssh_opts = $(shell echo $(ssh_opts) \
	| sed -e 's:\(User=\)[^ ]*:\1ops:' \
		-e "s:\\(IdentityFile=\\)[^ ]*:\1/tmp/.ssh/insecure_id_rsa:")
vagrant_ssh_opts = \
$(shell echo $(ssh_opts) | sed -e 's:\(User=\)[^ ]*:\1vagrant:')

target = $(shell if [ -z "${TARGET}" ]; then \
	echo "-l lxc_hosts"; else echo "-l ${TARGET},"; fi)

default: help

clean: ## Clean
	find . -type f -name \*~ -exec rm -f {} \+
	rm -f *.retry

help: ## Show this help
	@printf '\033[32mtargets:\033[0m\n'
	@grep -E '^[a-zA-Z _-]+:.*?## .*$$' $(MAKEFILE_LIST) |\
		sort |\
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n",$$1,$$2}'

destroy: ## Destroy Vagrant sandbox
	vagrant destroy -f

up: ## Vagrant up sandbox
	vagrant up

halt: ## Vagrant up sandbox
	vagrant halt

rebuild: ## Rebuild Vagrant sandbox
	@make destroy up

initlxc: ## Initialize LXC environment
	ssh $(vagrant_ssh_opts) -t sandbox sudo /usr/local/bin/init_lxc.sh

addkey: ## Add 'ops' insecure SSH Key to ssh-agent
	install -m 0700 -d /tmp/.ssh
	ssh $(vagrant_ssh_opts) sandbox sudo cat /home/ops/.ssh/insecure_id_rsa \
		> /tmp/.ssh/insecure_id_rsa
	chmod 0600 /tmp/.ssh/insecure_id_rsa
	ssh-add /tmp/.ssh/insecure_id_rsa

ping: ## Check ansible access on LXC hosts
	ansible -i inventory.sh all -m shell -a 'echo "$$(hostname -f): $$(uptime)"'
	if ansible -i inventory.sh sandbox.local -a 'ls -laF /root'; then \
		false; \
	else \
		true; \
	fi
	ansible -i inventory.sh sandbox.local --become -a 'ls -laF /root'

check: ## Check playbook.yml on $TARGET LXC host (all if not set)
	ansible-playbook -i inventory.sh --check --diff $(target) playbook.yml

shell: ## ssh as 'ops' inside Vagrant sandbox
	ssh $(ops_ssh_opts) -t sandbox

squidtail: ## Tail squid HTTP proxy logs
	ssh $(vagrant_ssh_opts) -t sandbox sudo tail -F /var/log/squid/\*.log

dnsmasqtail: ## Tail dnsmasq DNS proxy & DHCP server logs
	ssh $(vagrant_ssh_opts) -t sandbox sudo journalctl -f -u dnsmasq.service

eximtail: ## Tail exim SMTP server logs
	ssh $(vagrant_ssh_opts) -t sandbox sudo tail -F /var/log/exim4/mainlog

provision: ## Provision playbook.yml on $TARGET LXC host (all if not set)
	ansible-playbook -i inventory.sh --diff $(target) playbook.yml

inventory: ## Show dynamic inventory
	@./inventory.sh

todo:
	@find . -type f ! -name \*~ -exec egrep '(TODO|FIXME):' {} \+ | grep -v @find

validate: ## Validate playbook.yml
	@ssh $(ops_ssh_opts) -t sandbox \
		'for index in $$(seq 2 9); do \
			echo dhcp00$${index}---------------------------------------------------; \
			ssh dhcp00$${index} uptime; \
		done'
	# TODO: add GET HTTP 'Accept: text/html' validation
	# TODO: add dhcp00X.local matching HTTP response body validation
	# TODO: add SMTP listening on 127.0.0.1:25 validation
	# TODO: add mail relay orig. to webmaster@dhcp00X.local to ops@sandbox.local

reset: ## Reset ssh-agent keys
	ssh-add -D
	ps ux \
		| egrep -v awk \
		| awk '/ssh:.*(ansible|vagrant)/ { print $$2; }' \
		| xargs kill 2> /dev/null || true
	if [ -d /tmp/.ssh ]; then rm -rf /tmp/.ssh; fi

test: ## Test all from scratch
	@make reset rebuild initlxc addkey ping halt up ping check provision validate
