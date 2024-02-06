ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.Phony: serve
serve:
	mdbook serve --port 8000

.Phony: build
build:
	mdbook build

.Phony: sponsor
sponsor:
	cd ../lib/scripts/docs/sponsorkit && npm start

.Phony: contributor
contributor:
	cd ../lib/scripts/docs/sponsorkit && npm run contributors

.PHONY: svghash
svghash:
	node ../lib/scripts/docs//add-svg-version.mjs

# .Phony: contributor
# contributor:
# 	npx github-contributors-list --owner <YOUR GIT USERNAME> --repo <TOOL REPO> --cols 6 --authToken $(PERSONAL_GITHUB_TOKEN) --filter "github-actions[bot]"

.Phony: publish
publish:
	wrangler pages publish ./book --project-name asdf-<YOUR TOOL>

.Phony: sync
sync:
	cp ./docs/README.md ./README---.md
