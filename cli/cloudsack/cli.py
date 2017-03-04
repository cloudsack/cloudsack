#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals

import sys
import argparse

from cloudsack import utils
from cloudsack import commands


def main():
    parser = argparse.ArgumentParser()

    subparser = parser.add_subparsers(title='Basic commands')
    build_img_parser = subparser.add_parser(
        'build-image', help='Builds container images.')
    build_img_parser.add_argument(
        'config',
        type=utils.yaml_file,
        help='A yaml file with configuration for build.',
    )
    build_img_parser.add_argument(
        '--components',
        nargs='+',
        type=str,
        dest='component_names',
        help='Takes space separated component names.',
    )
    build_img_parser.set_defaults(task=commands.Build)

    launch_parser = subparser.add_parser(
        'launch', help='Launch components in containers.')
    launch_parser.add_argument(
        'config',
        type=utils.yaml_file,
        help='A yaml file with configuration to launch.',
    )
    launch_parser.add_argument(
        '--components',
        nargs='+',
        type=str,
        dest='component_names',
        help='Takes space separated component names.',
    )
    launch_parser.set_defaults(task=commands.Launch)

    args = parser.parse_args(sys.argv[1:])
    args.task(args)()
