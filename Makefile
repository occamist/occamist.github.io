.PHONY: submodule-init submodule-update dev lint

submodule-init:
	git submodule update --init --recursive

submodule-update:
	git submodule update --remote --merge

dev:
	hugo server -D

lint:
	pnpm dlx markdownlint-cli2 "content/posts/**/*.md"
