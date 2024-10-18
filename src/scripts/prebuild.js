const path = require('path')
const fs = require('fs')
const os = require('os')
const {
	globSync,
} = require('glob')

const root = path.join(__dirname, '..')
const vendorPath = path.join(root, 'vendor')
const sodiumPath = path.join(vendorPath, 'libsodium')

const extractSodiumVersion = () => {
	const configure = fs.readFileSync(path.join(sodiumPath, 'configure.ac'), 'utf-8')
	const version = configure.match(/(?<=AC_INIT\(\[libsodium],\[).*?(?=\])/).pop()
	const minor = configure.match(/(?<=SODIUM_LIBRARY_VERSION_MAJOR=)\d+?(?=\s)/).pop()
	const patch = configure.match(/(?<=SODIUM_LIBRARY_VERSION_MINOR=)\d+?(?=\s)/).pop()
	return {
		version: version,
		major: minor,
		minor: patch,
	}
}

const writeVersionHeader = (buildMinimal = false) => {
	const version = extractSodiumVersion()
	const templatePath = path.join(sodiumPath, 'src/libsodium/include/sodium/version.h.in')
	const outputPath = path.join(sodiumPath, 'src/libsodium/include/sodium/version.h')
	const versionTemplate = fs.readFileSync(templatePath, 'utf-8')
		.replace('@VERSION@', version.version)
		.replace('@SODIUM_LIBRARY_VERSION_MAJOR@', version.major)
		.replace('@SODIUM_LIBRARY_VERSION_MINOR@', version.minor)
		.replace('@SODIUM_LIBRARY_MINIMAL_DEF@', buildMinimal ? '#define SODIUM_LIBRARY_MINIMAL 1' : '')
	fs.writeFileSync(outputPath, versionTemplate)
}

const cleanZigCache = () => {
	const zigBuildPath = path.join(root, 'zig-cache')
	fs.rmSync(zigBuildPath, { recursive: true, force: true })
}

const generate = () => {
	writeVersionHeader()
	writeSodiumGyp()
}

generate()