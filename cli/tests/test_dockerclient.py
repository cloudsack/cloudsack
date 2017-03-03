#!/usr/bin/python
# -*- coding: utf-8 -*-

import pytest

from cloudsack.dockerclient import Docker


class TestDocker(object):

    @pytest.fixture(autouse=True)
    def setup(self, monkeypatch, mocker):
        client_mock = mocker.MagicMock()
        mock = mocker.MagicMock(return_value=client_mock)
        monkeypatch.setattr(
            'cloudsack.dockerclient.docker.from_env', mock)
        docker = Docker()
        yield {'mock': mock, 'client_mock': client_mock, 'docker': docker}

    def test_build_image_connect(self, setup):
        docker = setup['docker']
        mock = setup['mock']
        client_mock = setup['client_mock']
        path = '/tmp/test'
        image_name = 'localhost:5000/test/version_core:v1'
        docker.build_image(path, image_name)
        mock.assert_called
        client_mock.images.build.assert_called_with(
            path=path,
            tag=image_name,
            timeout=600,
            rm=True,
            forcerm=True,
        )
        client_mock.images.push.assert_called_with(
            image_name,
            stream=True,
            insecure_registry=False,
        )
