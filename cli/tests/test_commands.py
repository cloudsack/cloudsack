#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals

from argparse import Namespace

import pytest

from cloudsack import commands, const


class TestBuild(object):

    @pytest.fixture(autouse=True)
    def setup(self, monkeypatch, mocker):
        config = {
            'docker': {
                'registry': 'registry',
                'username': 'username',
                'os_version': 'osversion',
                'tag': 'tag',
                'base_image': 'base_image',
            },
        }
        args = Namespace(config=config, component_names=None)
        build_mock = mocker.MagicMock()
        director_mock = mocker.MagicMock(return_value=build_mock)
        component_mock = mocker.MagicMock(return_value='component')
        component_factory_mock = mocker.MagicMock(return_value=component_mock)
        monkeypatch.setattr('cloudsack.commands.Director', director_mock)
        monkeypatch.setattr(
            'cloudsack.commands.component_factory', component_factory_mock)
        command = commands.Build(args)
        yield {
            'build_mock': build_mock,
            'director_mock': director_mock,
            'component_mock': component_mock,
            'component_factory_mock': component_factory_mock,
            'command': command,
            'config': config,
        }

    def test_prepare(self, setup):
        command = setup['command']
        command()
        assert command.args.component_names == const.COMPONENTS
        command.args.component_names = [1, 2, 3]
        command()
        assert command.args.component_names == [1, 2, 3]

    def test_component_factory(self, setup, mocker):
        command = setup['command']
        component_factory_mock = setup['component_factory_mock']
        command()
        calls = [
            mocker.call(component_name) for component_name in const.COMPONENTS]
        component_factory_mock.assert_has_calls(calls)

    def test_component(self, setup, mocker):
        config = setup['config']
        command = setup['command']
        component_mock = setup['component_mock']
        command()
        calls = [
            mocker.call(config) for _ in const.COMPONENTS]
        component_mock.assert_has_calls(calls)

    def test_director(self, setup, mocker):
        command = setup['command']
        director_mock = setup['director_mock']
        command()
        director_mock.assert_any_call('component')

    def test_build(self, setup, mocker):
        command = setup['command']
        build_mock = setup['build_mock']
        command()
        build_mock.build.assert_called()
