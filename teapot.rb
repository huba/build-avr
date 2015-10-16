# Teapot configuration generated at 2015-10-16 18:23:51 +1300

required_version "1.0.0-rc12"

# Build Targets
define_target "build-avr" do |target|
	target.provides "Build/AVR" do
		define Rule, "compile.c" do
			input :source_file, pattern: /\.(c|cc|m)$/

			parameter :mmcu

			output :object_file

			apply do |params|
				input_root = params[:source_file].root

				run!("avr-gcc",
						 "-c",
						 "-mmcu=" + params[:mmcu],
						 params[:source_file].relative_path,
						 *environment[:cflags].flatten,
						 "-o", parameters[:object_file].shortest_path(input_root)
						)
			end
		end

		define Rule, "link.elf" do
			input :object_files, pattern: /\.o/, multiple: true

			parameter :mmcu

			output :elf_file, pattern: /\.out/

			apply do |params|
				input_root = params[:elf_file].root
				object_files = params[:object_files].collect{|path| path.shortest_path(input_root)}

				run!("avr-gcc",
						 "-mmcu=" + params[:mmcu],
						 *environment[:cflags].flatten,
						 *object_files,
						 "-o", params[:elf_file],
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

			parameter :elf, pattern: /\.put/

			output :elf_file, implicit: true do |args|
				args[:prefix] / args[:elf]
			end

			apply do |params|
				build_prefix = params[:build_prefix]

				object_files = params[:source_files].collect do |source_file|
					object_file = build_prefix + (source_file.relative_path + ".o")
					fs.mkpath File.dirname(object_file)

					compile source_file: source_file, object_file: object_file, mmcu: params[:mmcu]
				end

				link object_files: object_files, elf_file: params[:elf_file], mmcu: params[:mmcu]
			end
		end
	end

	target.provides "Flash/AVR" do
		define Rule, "copy.elf" do
			input :elf_file, pattern: /\.out/
			output :hex_file, pattern: /\.hex/

		end

		define Rule, "dfu.erease" do

		end

		define Rule, "dfu.flash" do

		end

		define Rule, "dfu.start" do

		end
	end

	target.provides "Language/C99" do
		cflags = "-Os -Wall -Wstrict-prototypes -Wextra -g"
	end
end
