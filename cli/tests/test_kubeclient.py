#!/usr/bin/python
# -*- coding: utf-8 -*-

from builtins import object

import os

import pytest

from cloudsack.kubeclient import Kube


class TestKube(object):

    @pytest.fixture(autouse=True)
    def setup(self, monkeypatch, mocker):
        api_mock = mocker.MagicMock()
        http_client_mock = mocker.MagicMock(return_value=api_mock)
        kube_config_mock = mocker.MagicMock()
        monkeypatch.setattr(
            'cloudsack.kubeclient.pykube.HTTPClient',
            http_client_mock,
        )
        monkeypatch.setattr(
            'cloudsack.kubeclient.pykube.KubeConfig',
            kube_config_mock,
        )
        kube = Kube()
        yield {
            'api_mock': api_mock,
            'http_client_mock': http_client_mock,
            'kube_config_mock': kube_config_mock,
            'kube': kube,
        }

    def test__init__(self, setup):
        setup['http_client_mock'].assert_called()
        setup['kube_config_mock'].from_file.assert_called()

    def test_create_job(self, setup, mocker, monkeypatch):
        kube = setup['kube']
        api_mock = setup['api_mock']
        instance_mock = mocker.MagicMock()
        job_mock = mocker.MagicMock(return_value=instance_mock)
        monkeypatch.setattr(
            'cloudsack.kubeclient.pykube.Job',
            job_mock,
        )
        file_name = os.path.join(
            os.path.abspath(
                os.path.dirname(__file__)), 'copyme', 'template.yaml')
        kube.create_job(file_name)
        job_mock.assert_called_with(api_mock, {'a': 'b', 'c': 'd'})
        instance_mock.create.assert_called()
