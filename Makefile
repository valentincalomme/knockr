# Required .PHONY targets
.PHONY: all clean

SRC_DIR := src/
TESTS_DIR := tests/

MODULES := ${SRC_DIR} ${TESTS_DIR}
PYTHON_VERSIONS := 10 11 12 13

# If a python version is provided as an environment variable, run the command
# using a dedicated virtual environment, otherwise, just run the command.
UV_RUN = $(if $(PYTHON_VERSION), \
	VIRTUAL_ENV=".3${PYTHON_VERSION}.venv" \
	UV_PROJECT_ENVIRONMENT=".3${PYTHON_VERSION}.venv" \
	uv run --python 3.${PYTHON_VERSION}, \
	uv run)

.PHONY: init # Run this command to setup the project
init: lock install install-pre-commit build

.PHONY: install # Installs main and dev dependencies
install:
	uv sync --all-extras --dev --locked

.PHONY: install-pre-commit # Install pre-commit hooks
install-pre-commit:
	uv run pre-commit install --install-hooks

.PHONY: build # Build the package
build:
	uv build

.PHONY: publish # Publish the package
publish:
	make build
	UV_PUBLISH_TOKEN=${UV_PUBLISH_TOKEN} uv publish

.PHONY: lock # Lock the dependency versions
lock:
	uv lock

.PHONY: upgrade # Upgrade all dependencies given the dependency constraints
upgrade:
	uv lock --upgrade
	make install
	@if ! git diff --exit-code --quiet uv.lock; then \
		uv run pre-commit autoupdate; \
	fi

#------------------------------------- CI scripts -------------------------------------#

.PHONY: ci # Run ci for all python versions
ci:
	make build
	make qa
	make test
	make docs

.PHONY: qa # Run qa for all python versions
qa:
	@$(foreach v, $(PYTHON_VERSIONS), $(MAKE) qa-version PYTHON_VERSION=$(v) || exit 1;)

.PHONY: test # Run test for all support python versions
test:
	@$(foreach v, $(PYTHON_VERSIONS), $(MAKE) test-version PYTHON_VERSION=$(v) || exit 1;)
	@uv run coverage combine
	@uv run coverage report

.PHONY: qa-version # Code quality checks
qa-version:
	@${UV_RUN} ruff check --no-fix --preview ${MODULES}
	@${UV_RUN} mypy --incremental ${MODULES}
	@${UV_RUN} pyright

.PHONY: test-version # Run tests (including doctests) and compute coverage
test-version:
	@${UV_RUN} pytest --cov=${SRC_DIR} --doctest-modules --cov-report=html
	@if [ -n "$${PYTHON_VERSION}" ]; then \
		@mv .coverage .coverage.3${PYTHON_VERSION}; \
	fi

.PHONY: docs # Build the documentation and break on any warnings/errors
docs:
	@uv run mkdocs build --strict

.PHONY: fix # Fixes issues in the codebase
fix:
	@uv run ruff check ${MODULES} --fix --preview
	@uv run ruff format ${MODULES}
