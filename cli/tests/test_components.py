#!/usr/bin/python
# -*- coding: utf-8 -*-

from builtins import object

from cloudsack import utils
from cloudsack.components import Base


class TestBase(object):

    def test_fqin(self):
        config = {
            'docker': {
                'registry': 'localhost:5000',
                'username': 'test',
                'os_version': 'version',
                'tag': 'v1',
                'base_image': 'test',
            }
        }
        component = Base(config)
        component.name = 'core'
        expected = utils.get_fqin(
            'localhost:5000',
            'test',
            'version',
            'v1',
            'core',
        )
        result = component.fqin
        assert result == expected

    def test_build_context(self):
        config = {
            'docker': {
                'registry': 'localhost:5000',
                'username': 'test',
                'os_version': 'version',
                'tag': 'v1',
                'base_image': 'test',
            }
        }
        component = Base(config)
        base_fqin = utils.get_fqin(
            'localhost:5000',
            'test',
            'version',
            'v1',
            'test',
        )
        expected = {'base_fqin': base_fqin}
        result = component.build_context
        assert result == expected
