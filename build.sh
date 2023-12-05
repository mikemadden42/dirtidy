#!/bin/sh -x

swiftc -O -whole-module-optimization -gnone -target arm64-apple-macos11 -o dirtidy-arm64 dirtidy.swift
swiftc -O -whole-module-optimization -gnone -target x86_64-apple-macos11 -o dirtidy-x86_64 dirtidy.swift
lipo -create \
	dirtidy-arm64 \
	dirtidy-x86_64 \
	-output dirtidy
strip dirtidy
codesign -s - dirtidy
