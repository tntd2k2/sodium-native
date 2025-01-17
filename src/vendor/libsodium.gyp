{
	'variables': {
		'target_endianness%': 'le',
	},
	'targets': [{
		'target_name': 'libsodium',
		'type': 'static_library',
		'include_dirs': [
			'./libsodium/src/libsodium/include/sodium',
		],
		'defines': [
			'SODIUM_STATIC=1',
			'_GNU_SOURCE=1',
			'CONFIGURED=1',
			'DEV_MODE=1',
			'HAVE_ATOMIC_OPS=1',
			'HAVE_C11_MEMORY_FENCES=1',
			'HAVE_CET_H=1',
			'HAVE_GCC_MEMORY_FENCES=1',
			'HAVE_INLINE_ASM=1',
			'HAVE_INTTYPES_H=1',
			'HAVE_STDINT_H=1',
			'HAVE_TI_MODE=1'
		],
		'xcode_settings': {
			'OTHER_CFLAGS': [
				'-fvisibility=hidden',
				'-fno-strict-aliasing',
				'-fno-strict-overflow',
				'-fwrapv',
				'-flax-vector-conversions',
				'-Wno-unused-function',
				'-Wno-unknown-pragmas',
				'-Wno-unused-but-set-variable',
			],
		},
		'sources': [],
		'configurations': {
			'Release': {
				'defines': ['NDEBUG'],
			},
		},
		'conditions': [
			['target_endianness=="le"', {
				'defines': [
					'NATIVE_LITTLE_ENDIAN=1',
				],
			}, {
				'defines': [
					'NATIVE_BIG_ENDIAN=1',
				],
			}],
			['OS=="linux"', {
				'defines': [
					'ASM_HIDE_SYMBOL=.hidden',
					'TLS=_Thread_local',
					'HAVE_CATCHABLE_ABRT=1',
					'HAVE_CATCHABLE_SEGV=1',
					'HAVE_CLOCK_GETTIME=1',
					'HAVE_GETPID=1',
					'HAVE_MADVISE=1',
					'HAVE_MLOCK=1',
					'HAVE_MMAP=1',
					'HAVE_MPROTECT=1',
					'HAVE_NANOSLEEP=1',
					'HAVE_POSIX_MEMALIGN=1',
					'HAVE_PTHREAD_PRIO_INHERIT=1',
					'HAVE_PTHREAD=1',
					'HAVE_RAISE=1',
					'HAVE_SYSCONF=1',
					'HAVE_SYS_AUXV_H=1',
					'HAVE_SYS_MMAN_H=1',
					'HAVE_SYS_PARAM_H=1',
					'HAVE_SYS_RANDOM_H=1',
					'HAVE_WEAK_SYMBOLS=1',
				],
			}],
			['OS=="win"', {
				'defines': [
					'_CRT_SECURE_NO_WARNINGS=1',
					'HAVE_RAISE=1',
					'HAVE_SYS_PARAM_H=1',
				],
			}],
			['OS=="mac"', {
				'defines': [
					'ASM_HIDE_SYMBOL=.private_extern',
					'TLS=_Thread_local',
					'HAVE_ARC4RANDOM=1',
					'HAVE_ARC4RANDOM_BUF=1',
					'HAVE_CATCHABLE_ABRT=1',
					'HAVE_CATCHABLE_SEGV=1',
					'HAVE_CLOCK_GETTIME=1',
					'HAVE_GETENTROPY=1',
					'HAVE_GETPID=1',
					'HAVE_MADVISE=1',
					'HAVE_MEMSET_S=1',
					'HAVE_MLOCK=1',
					'HAVE_MMAP=1',
					'HAVE_MPROTECT=1',
					'HAVE_NANOSLEEP=1',
					'HAVE_POSIX_MEMALIGN=1',
					'HAVE_PTHREAD=1',
					'HAVE_PTHREAD_PRIO_INHERIT=1',
					'HAVE_RAISE=1',
					'HAVE_SYSCONF=1',
					'HAVE_SYS_MMAN_H=1',
					'HAVE_SYS_PARAM_H=1',
					'HAVE_SYS_RANDOM_H=1',
					'HAVE_WEAK_SYMBOLS=1',
				]
			}],
			['target_arch=="x64"', {
				'defines': [
					'HAVE_CPUID=1',
					'HAVE_MMINTRIN_H=1',
					'HAVE_EMMINTRIN_H=1',
					'HAVE_PMMINTRIN_H=1',
					'HAVE_TMMINTRIN_H=1',
					'HAVE_SMMINTRIN_H=1',
					'HAVE_AVXINTRIN_H=1',
					'HAVE_AVX2INTRIN_H=1',
					'HAVE_AVX512FINTRIN_H=1',
					'HAVE_WMMINTRIN_H=1',
					'HAVE_RDRAND=1',
				],
				'conditions': [
					['OS!="win"', {
						'defines': [
							'HAVE_AMD64_ASM=1',
							'HAVE_AVX_ASM=1',
						],
						'sources': ['.\\libsodium\\src\\libsodium\\crypto_stream\\salsa20\\xmm6\\salsa20_xmm6-asm.S','.\\libsodium\\src\\libsodium\\crypto_scalarmult\\curve25519\\sandy2x\\sandy2x.S','.\\libsodium\\src\\libsodium\\crypto_scalarmult\\curve25519\\sandy2x\\ladder.S','.\\libsodium\\src\\libsodium\\crypto_scalarmult\\curve25519\\sandy2x\\fe51_pack.S','.\\libsodium\\src\\libsodium\\crypto_scalarmult\\curve25519\\sandy2x\\fe51_nsquare.S','.\\libsodium\\src\\libsodium\\crypto_scalarmult\\curve25519\\sandy2x\\fe51_mul.S','.\\libsodium\\src\\libsodium\\crypto_scalarmult\\curve25519\\sandy2x\\consts.S'],
					}],
				],
			}],
		],
	}],
}
