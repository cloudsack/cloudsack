#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals

from setuptools import setup


with open('requirements.txt') as stream:
    install_requires = stream.read().strip().splitlines()


# TODO: Pick version from release.py
setup(
    name='cloudsack',
    version='1.0',
    description='Containerized openstack deployment.',
    long_description='',
    author='Ansuman Bebarta',
    author_email='ansuman.bebarta@gmail.com',
    url='',
    license='MIT',
    py_modules=['cloudsack'],
    install_requires=['docker', 'Jinja2', 'pykube', 'future'],
    entry_points={
        'console_scripts': ['csack=cloudsack.cli:main']
    },
)
