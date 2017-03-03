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
        '--images',
        nargs='+',
        type=str,
        dest='image_names',
        help='Takes space separated image names.',
    )
    build_img_parser.set_defaults(task=commands.Build)

    args = parser.parse_args(sys.argv[1:])
    args.task(args).perform()
