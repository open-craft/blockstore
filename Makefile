.DEFAULT_GOAL := test

.PHONY: clean compile_translations dummy_translations extract_translations fake_translations help html_coverage \
	migrate pull_translations push_translations quality requirements test update_translations validate

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  clean                      delete generated byte code and coverage reports"
	@echo "  compile_translations       compile translation files, outputting .po files for each supported language"
	@echo "  dummy_translations         generate dummy translation (.po) files"
	@echo "  extract_translations       extract strings to be translated, outputting .mo files"
	@echo "  fake_translations          generate and compile dummy translation files"
	@echo "  help                       display this help message"
	@echo "  html_coverage              generate and view HTML coverage report"
	@echo "  migrate                    apply database migrations"
	@echo "  production-requirements    install requirements for production"
	@echo "  static                     build static assets"
	@echo "  pull_translations          pull translations from Transifex"
	@echo "  push_translations          push source translation files (.po) from Transifex"
	@echo "  quality                    run PEP8 and Pylint"
	@echo "  requirements               install requirements for local development"
	@echo "  test                       run tests and generate coverage report"
	@echo "  validate                   run tests and quality checks"
	@echo "  start-devstack             run a local development copy of the server"
	@echo "  open-devstack              open a shell on the server started by start-devstack"
	@echo "  pkg-devstack               build the blockstore image from the latest configuration and code"
	@echo "  detect_changed_source_translations       check if translation files are up-to-date"
	@echo "  validate_translations      install fake translations and check if translation files are up-to-date"
	@echo ""

clean:
	find . -name '*.pyc' -delete
	coverage erase
	rm -rf assets

requirements:
	pip install -qr requirements/local.txt --exists-action w

production-requirements:
	pip install -qr requirements.txt --exists-action w

static:
	python manage.py collectstatic

test: clean
	coverage run ./manage.py test blockstore --settings=blockstore.settings.test
	coverage report

quality:
	pycodestyle --config=.pycodestylerc blockstore *.py
	pylint --rcfile=.pylintrc blockstore *.py

validate: test quality

migrate:
	python manage.py migrate

html_coverage:
	coverage html && open htmlcov/index.html

extract_translations:
	python manage.py makemessages -l en -v1 -d django
	python manage.py makemessages -l en -v1 -d djangojs

dummy_translations:
	cd blockstore && i18n_tool dummy

compile_translations:
	python manage.py compilemessages

fake_translations: extract_translations dummy_translations compile_translations

pull_translations:
	tx pull -af --mode reviewed

push_translations:
	tx push -s

start-devstack:
	docker-compose --x-networking up

open-devstack:
	docker exec -it blockstore /edx/app/blockstore/devstack.sh open

pkg-devstack:
	docker build -t blockstore:latest -f docker/build/blockstore/Dockerfile git://github.com/edx/configuration

detect_changed_source_translations:
	cd blockstore && i18n_tool changed

validate_translations: fake_translations detect_changed_source_translations
