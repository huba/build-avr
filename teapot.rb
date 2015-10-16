# Teapot configuration generated at 2015-10-16 18:23:51 +1300

required_version "1.0.0-rc12"

# Build Targets
define_target "build-avr" do |target|
	target.provides "Build/AVR" do
		define Rule, "compile.c" do
			input :source_file, pattern: /\.(c|cc|m)$/

			parameter :mmcu

			output :object_file

			apply do |parameters|
				run!("avr-gcc",
						 "-c",
						 "-mmcu=" + parameters[:mmcu],
						 parameters[:source_file],
						 *environment[:cflags].flatten,
						 "-o", parameters[:object_file]
						)
			end
		end

		define Rule, "link.elf" do
			input :object_files, pattern: /\.o/, multiple: true

			parameter :mmcu

			output :elf_file, pattern: /\.out/

			apply do |parameters|
				object_files = parameters[:object_files]

				run!("avr-gcc",
						 "-mmcu=" + parameters[:mmcu],
						 *environment[:cflags].flatten,
						 *object_files,
						 "-o", parameters[:elf_file],
						 "-lm"
						)
			end
		end

		define Rule, "build.binary" do
			input :source_files

			parameter :build_prefix
			parameter :mmcu, optional: true do |mmcu, args|
				args[:mmcu] = mmcu || "atmega32u2"
			end

			parameter :elf, pattern: /\.out/

			output :elf_file, implicit: true do |args|
				args[:build_prefix] / args[:elf]
			end

			apply do |parameters|
				build_prefix = parameters[:build_prefix]

				object_files = parameters[:source_files].collect do |source_file|
					object_file = build_prefix + (source_file.relative_path + ".o")
					fs.mkpath File.dirname(object_file)

					compile source_file: source_file, object_file: object_file, mmcu: parameters[:mmcu]
				end

				link object_files: object_files, elf_file: parameters[:elf_file], mmcu: parameters[:mmcu]
			end
		end
	end

	target.provides "Flash/AVR" do
		define Rule, "copy.elf" do
			input :elf_file, pattern: /\.out/
			output :hex_file, pattern: /\.hex/

			apply do |parameters|
				run!("avr-objcopy",
						 "-O", "ihex",
						 parameters[:elf_file],
						 parameters[:hex_file]
						)
			end
		end

		define Rule, "dfu.erease" do
			parameter :mmcu, optional: true do |mmcu, args|
				args[:mmcu] = mmcu || "atmega32u2"
			end

			apply do |parameters|
				run!("dfu-programmer",
						 parameters[:mmcu],
						 "erase"
						)
			end
		end

		define Rule, "dfu.flash" do
			input :hex_file, pattern: /\.hex/

			parameter :mmcu, optional: true do |mmcu, args|
				args[:mmcu] = mmcu || "atmega32u2"
			end

			apply do |parameters|
				run!("dfu-programmer",
						 parameters[:mmcu],
						 parameters[:hex_file]
						)
			end
		end

		define Rule, "dfu.start" do
			parameter :mmcu, optional: true do |mmcu, args|
				args[:mmcu] = mmcu || "atmega32u2"
			end

			apply do |parameters|
				run!("dfu-programmer",
						 parameters[:mmcu],
						 "start"
						)
			end
		end
	end

	target.provides "Language/C99" do
		cflags %W{-Os -Wall -Wstrict-prototypes -Wextra -g}
	end
end
