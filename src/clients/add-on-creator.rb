# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2006-2012 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	clients/add-on-creator.ycp
# Package:	Configuration of add-on-creator
# Summary:	Main file
# Authors:	Jiri Suchomel <jsuchome@suse.cz>
#
# $Id$
#
# Main file for add-on-creator configuration. Uses all other files.
module Yast
  class AddOnCreatorClient < Client
    def main
      Yast.import "UI"

      #**
      # <h3>Configuration of add-on-creator</h3>

      textdomain "add-on-creator"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("AddOnCreator module started")

      Yast.import "AddOnCreator"
      Yast.import "CommandLine"
      Yast.import "Directory"
      Yast.import "FileUtils"

      Yast.include self, "add-on-creator/wizards.rb"

      @cmdline_description = {
        "id"         => "add-on-creator",
        # Command line help text for the add-on-creator module
        "help"       => _(
          "Creator for add-on products"
        ),
        "guihandler" => fun_ref(method(:AddOnCreatorSequence), "any ()"),
        "initialize" => fun_ref(AddOnCreator.method(:Read), "boolean ()"),
        "finish"     => fun_ref(AddOnCreator.method(:Write), "boolean ()"),
        "actions"    => {
          "create" => {
            "handler" => fun_ref(
              method(:CreateAddOn),
              "boolean (map <string, any>)"
            ),
            # command line help text for 'create' action
            "help"    => _(
              "Create and build a new add-on product."
            )
          },
          "clone"  => {
            "handler" => fun_ref(
              method(:CloneAddOn),
              "boolean (map <string, any>)"
            ),
            # command line help text for 'clone' action
            "help"    => _(
              "Create and build a new add-on product based on an existing one."
            )
          },
          "sign"   => {
            "handler" => fun_ref(
              method(:SignAddOn),
              "boolean (map <string, any>)"
            ),
            # command line help text for 'sign' action
            "help"    => _(
              "Sign unsigned Add-On Product"
            )
          },
          "list"   => {
            "handler" => fun_ref(
              method(:ListAddOns),
              "boolean (map <string, any>)"
            ),
            # command line help text for 'list' action
            "help"    => _(
              "List available add-on product configurations."
            )
          },
          "build"  => {
            "handler" => fun_ref(
              method(:BuildAddOnHandler),
              "boolean (map <string, any>)"
            ),
            # command line help text for 'create' action
            "help"    => _(
              "Build an add-on product from the selected configuration."
            )
          },
          "delete" => {
            "handler" => fun_ref(
              method(:DeleteAddOn),
              "boolean (map <string, any>)"
            ),
            # command line help text for 'create' action
            "help"    => _(
              "Delete the selected add-on product configuration."
            )
          }
        },
        "options"    => {
          "rpm_dir"                  => {
            # command line help text for 'rpm_dir' option
            "help" => _(
              "Path to directory with packages"
            ),
            "type" => "string"
          },
          "content"                  => {
            # command line help text for 'content' option (do not translate 'content', it's a name)
            "help" => _(
              "Path to content file"
            ),
            "type" => "string"
          },
          "existing"                 => {
            # command line help text for 'existing' option
            "help" => _(
              "Path to directory with existing Add-On Product"
            ),
            "type" => "string"
          },
          "generate_descriptions"    => {
            # command line help text for 'generate_descriptions' option
            "help" => _(
              "Generate new package descriptions (do not copy)"
            )
          },
          "package_descriptions_dir" => {
            # command line help text for 'package_descriptions_dir' option
            "help" => _(
              "Path to directory with package descriptions"
            ),
            "type" => "string"
          },
          "patterns_dir"             => {
            # command line help text for 'patterns_dir' option
            "help" => _(
              "Path to directory with patterns definitions"
            ),
            "type" => "string"
          },
          "output_dir"               => {
            # command line help text for 'output_dir' option
            "help" => _(
              "Path to the output directory"
            ),
            "type" => "string"
          },
          "create_iso"               => {
            # command line help text for 'create_iso' option
            "help" => _(
              "Create the ISO image"
            )
          },
          "iso_name"                 => {
            # command line help text for 'iso_name' option
            "help" => _(
              "Name of the output ISO image"
            ),
            "type" => "string"
          },
          "iso_output_dir"           => {
            # command line help text for 'output_dir' option
            "help" => _(
              "Path to the output directory for ISO image"
            ),
            "type" => "string"
          },
          "do_not_sign"              => {
            # command line help text for 'do_not_sign' option
            "help" => _(
              "Do not sign the product"
            )
          },
          "gpg_key"                  => {
            # command line help text for 'gpg_key' option
            "help" => _(
              "GPG key ID used to sign a product"
            ),
            "type" => "string"
          },
          "passphrase"               => {
            # command line help text for 'passphrase' option
            "help" => _(
              "Passphrase to unlock GPG key"
            ),
            "type" => "string"
          },
          "passphrase_file"          => {
            # command line help text for 'passphrase_file' option
            "help" => _(
              "Path to file with the passphrase for GPG key"
            ),
            "type" => "string"
          },
          "resign_packages"          => {
            # command line help text for 'passphrase' option
            "help" => _(
              "Resign all packages with selected key."
            )
          },
          "workflow"                 => {
            # command line help text for 'workflow' option
            "help" => _(
              "Path to workflow definition file (installation.xml)"
            ),
            "type" => "string"
          },
          "y2update"                 => {
            # command line help text for 'y2update' option
            "help" => _(
              "Path to workflow dialogs archive (y2update.tgz)"
            ),
            "type" => "string"
          },
          "y2update_packages_dir"    => {
            # command line help text for 'y2update_packages_dir' option
            "help" => _(
              "Path to directory with YaST packages to form the workflow"
            ),
            "type" => "string"
          },
          "license"                  => {
            # command line help text for 'license' option
            "help" => _(
              "Path to file with license texts (license.zip or license.tar.gz)"
            ),
            "type" => "string"
          },
          "info"                     => {
            # command line help text for 'info' option
            "help" => _(
              "Path to file with 'info' text (media.1/info.txt)"
            ),
            "type" => "string"
          },
          "extra_prov"               => {
            # command line help text for 'extra_prov' option
            "help" => _(
              "Path to file with additional dependencies (EXTRA_PROV)"
            ),
            "type" => "string"
          },
          "addon_dir"                => {
            # command line help text for 'addon-dir' option
            "help" => _(
              "Path to directory with Add-On Product"
            ),
            "type" => "string"
          },
          "do_not_build"             => {
            # command line help text for 'do_not_build' option
            "help" => _(
              "Do not build the product, only save new configuration."
            )
          },
          "number"                   => {
            # help text for 'number' option; do not translate 'list'
            "help" => _(
              "Number of the selected add-on (see 'list' command for product numbers)."
            ),
            "type" => "integer"
          },
          "changelog"                => {
            # command line help text for 'changelog' option
            "help" => _(
              "Generate a Changelog file."
            )
          },
          "no_release_package"       => {
            # command line help text for 'no_release_package' option
            "help" => _(
              "Do not generate the release package."
            )
          },
          "product_file"             => {
            # command line help text for 'product_file' option
            "help" => _(
              "Path to file with the product description (*.prod)"
            ),
            "type" => "string"
          }
        },
        "mappings"   => {
          "create" => [
            "content",
            "rpm_dir",
            "package_descriptions_dir",
            "patterns_dir",
            "output_dir",
            "create_iso",
            "iso_name",
            "gpg_key",
            "passphrase",
            "passphrase_file",
            "workflow",
            "y2update",
            "y2update_packages_dir",
            "license",
            "do_not_sign",
            "iso_output_dir",
            "resign_packages",
            "info",
            "extra_prov",
            "do_not_build",
            "changelog",
            "no_release_package",
            "product_file"
          ],
          "clone"  => [
            "existing",
            "generate_descriptions",
            "content",
            "package_descriptions_dir",
            "patterns_dir",
            "output_dir",
            "create_iso",
            "iso_name",
            "gpg_key",
            "passphrase",
            "passphrase_file",
            "workflow",
            "y2update",
            "y2update_packages_dir",
            "license",
            "do_not_sign",
            "iso_output_dir",
            "resign_packages",
            "info",
            "extra_prov",
            "do_not_build",
            "changelog",
            "no_release_package",
            "product_file"
          ],
          "sign"   => [
            "addon_dir",
            "gpg_key",
            "passphrase",
            "passphrase_file",
            "create_iso",
            "iso_name",
            "iso_output_dir",
            "resign_packages"
          ],
          "build"  => [
            "number",
            "gpg_key",
            "passphrase",
            "passphrase_file",
            "resign_packages",
            "create_iso",
            "iso_name",
            "iso_output_dir",
            "changelog",
            "no_release_package"
          ],
          "delete" => ["number"],
          "list"   => []
        }
      }

      @ret = CommandLine.Run(@cmdline_description)

      # Finish
      Builtins.y2milestone("AddOnCreator module finished with %1", @ret)
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end

    def ReportMissingFile(file)
      # error message, %1 is path
      Report.Error(Builtins.sformat(_("File %1 does not exist."), file))

      nil
    end

    def ReportMissingDir(dir)
      # error message, %1 is path
      Report.Error(Builtins.sformat(_("Directory %1 does not exist."), dir))

      nil
    end

    # helper for parsing command line data regarding iso creation
    def ParseISOData(options)
      options = deep_copy(options)
      current_product = {}
      Ops.set(current_product, "iso", Builtins.haskey(options, "create_iso"))
      if Builtins.haskey(options, "iso_name")
        Ops.set(current_product, "iso", true)
        Ops.set(
          current_product,
          "iso_name",
          Ops.get_string(options, "iso_name", "")
        )
      end
      if Builtins.haskey(options, "iso_output_dir")
        Ops.set(current_product, "iso", true)
        Ops.set(
          current_product,
          "iso_path",
          Ops.get_string(options, "iso_output_dir", "")
        )
      end
      deep_copy(current_product)
    end

    # helper for parsing command line data regarding product signing
    def ParseGPGData(options)
      options = deep_copy(options)
      current_product = {}
      key = Ops.get_string(options, "gpg_key", "")
      Ops.set(current_product, "gpg_key", key) if key != ""
      passphrase = Ops.get_string(options, "passphrase", "")
      if passphrase == "" && Builtins.haskey(options, "passphrase_file")
        file = Ops.get_string(options, "passphrase_file", "")
        if FileUtils.Exists(file)
          pass = Convert.to_string(SCR.Read(path(".target.string"), file))
          passphrase = pass if pass != nil
        else
          ReportMissingFile(file)
        end
      elsif passphrase == "" && key != ""
        passphrase =
          # question on command line
          CommandLine.PasswordInput(
            Builtins.sformat(
              _("Passphrase for key %1:"),
              Ops.get_string(current_product, "gpg_key", "")
            )
          )
      end
      Ops.set(AddOnCreator.passphrases, key, passphrase)
      Ops.set(current_product, "ask_for_passphrase", true)
      Ops.set(
        current_product,
        "resign_packages",
        Builtins.haskey(options, "resign_packages")
      )
      deep_copy(current_product)
    end

    # General function for creating new add-on
    def Create(options)
      options = deep_copy(options)
      current_product = deep_copy(AddOnCreator.current_product)
      if !Builtins.haskey(options, "output_dir")
        # error message
        Report.Error(_("Path to output directory is missing."))
        return false
      else
        Ops.set(
          current_product,
          "base_output_path",
          Ops.get_string(options, "output_dir", "")
        )
      end

      # now we can import different content file if it was provided
      if Builtins.haskey(options, "content")
        file = Ops.get_string(options, "content", "")
        if FileUtils.Exists(file)
          content = AddOnCreator.ReadContentFile(file)
          if content != nil
            AddOnCreator.content = deep_copy(content)
            AddOnCreator.UpdateContentMap(content)
          end
        else
          ReportMissingFile(file)
          return false if !AddOnCreator.clone
        end
      end
      if Builtins.haskey(options, "product_file")
        file = Ops.get_string(options, "product_file", "")
        if FileUtils.Exists(file)
          AddOnCreator.product_xml = AddOnCreator.ReadProductXML(file)
          AddOnCreator.product_info = AddOnCreator.GetProductInfo(
            AddOnCreator.product_xml,
            false
          )
        else
          ReportMissingFile(file)
          return false
        end
      end
      if Builtins.haskey(options, "package_descriptions_dir")
        dir = Ops.get_string(options, "package_descriptions_dir", "")
        if FileUtils.Exists(dir)
          # find all packages.langcode in dir and import them
          out = Convert.to_map(
            SCR.Execute(
              path(".target.bash_output"),
              Builtins.sformat("ls -A1 %1/packages.* 2>/dev/null", dir)
            )
          )
          packages_descr = Ops.get_map(current_product, "packages_descr", {})
          Builtins.foreach(
            Builtins.splitstring(Ops.get_string(out, "stdout", ""), "\n")
          ) do |file|
            f = Builtins.splitstring(file, ".")
            lang = Ops.get_string(f, Ops.subtract(Builtins.size(f), 1), "en")
            if lang == "gz"
              if Ops.greater_than(Builtins.size(f), 2)
                lang = Ops.get_string(
                  f,
                  Ops.subtract(Builtins.size(f), 2),
                  "en"
                )
              else
                next
              end
            end
            next if file == "" || lang == "DU" || lang == "FL"
            Ops.set(packages_descr, lang, AddOnCreator.ReadPackagesFile(file))
          end
          Ops.set(current_product, "packages_descr", packages_descr)
        else
          ReportMissingDir(dir)
        end
      end
      if Builtins.haskey(options, "patterns_dir")
        dir = Ops.get_string(options, "patterns_dir", "")
        if FileUtils.Exists(dir)
          # find all packages.langcode in dir and import them
          out = Convert.to_map(
            SCR.Execute(
              path(".target.bash_output"),
              Builtins.sformat("ls -A1 %1/*.pat 2>/dev/null", dir)
            )
          )
          patterns = {}
          Builtins.foreach(
            Builtins.splitstring(Ops.get_string(out, "stdout", ""), "\n")
          ) do |f|
            next if f == ""
            Builtins.foreach(AddOnCreator.ReadPatternsFile(f)) do |pat|
              if pat != {}
                full_name = Ops.get_string(pat, "Pat", "")
                pt = Builtins.splitstring(full_name, " ")
                if full_name != ""
                  Ops.set(pat, "name", Ops.get(pt, 0, ""))
                  Ops.set(pat, "version", Ops.get(pt, 1, ""))
                  Ops.set(pat, "release", Ops.get(pt, 2, ""))
                  Ops.set(pat, "arch", Ops.get(pt, 3, ""))
                  Ops.set(patterns, full_name, pat)
                end
              end
            end
          end
          Ops.set(current_product, "patterns", patterns)
        else
          ReportMissingDir(dir)
        end
      end
      current_product = Builtins.union(current_product, ParseISOData(options))

      if Builtins.haskey(options, "info")
        file = Ops.get_string(options, "info", "")
        if FileUtils.Exists(file)
          info = Convert.to_string(SCR.Read(path(".target.string"), file))
          Ops.set(current_product, "info", info) if info != nil
        else
          ReportMissingFile(file)
        end
      end
      if Builtins.haskey(options, "extra_prov")
        file = Ops.get_string(options, "extra_prov", "")
        if FileUtils.Exists(file)
          extra = Convert.to_string(SCR.Read(path(".target.string"), file))
          Ops.set(current_product, "extra_prov", extra) if extra != nil
        else
          ReportMissingFile(file)
        end
      end
      if Builtins.haskey(options, "license")
        file = Ops.get_string(options, "license", "")
        if FileUtils.Exists(file)
          pos = Builtins.findlastof(file, ".")
          tmpdir = Directory.tmpdir
          if Builtins.substring(file, pos) == ".zip"
            if !FileUtils.Exists("/usr/bin/unzip")
              # error message, missing tool
              Report.Error(_("/usr/bin/unzip does not exists"))
            else
              SCR.Execute(
                path(".target.bash_output"),
                Builtins.sformat("/usr/bin/unzip -o %1 -d %2", file, tmpdir)
              )
            end # let's try to unzip without checking file name and type...
          else
            SCR.Execute(
              path(".target.bash_output"),
              Builtins.sformat("/bin/tar -zxf %1 -C %2", file, tmpdir)
            )
          end
          out = Convert.to_map(
            SCR.Execute(
              path(".target.bash_output"),
              Builtins.sformat("ls -A1 %1/license*.txt 2>/dev/null", tmpdir)
            )
          )
          Builtins.foreach(
            Builtins.splitstring(Ops.get_string(out, "stdout", ""), "\n")
          ) do |f|
            next if f == ""
            name = Builtins.substring(
              f,
              Ops.add(Builtins.findlastof(f, "/"), 1)
            )
            if Builtins.issubstring(name, ".txt")
              name = Builtins.regexpsub(name, "^(.*).txt$", "\\1")
            end
            Builtins.y2milestone("Importing license file '%1'", f)
            cont = Convert.to_string(SCR.Read(path(".target.string"), f))
            if cont != nil
              Ops.set(current_product, ["license_files", name], cont)
            end
          end
        else
          ReportMissingFile(file)
        end
      end

      if Builtins.haskey(options, "workflow")
        file = Ops.get_string(options, "workflow", "")
        if FileUtils.Exists(file)
          Ops.set(current_product, "workflow_path", file)
        else
          ReportMissingFile(file)
        end
      end

      if Builtins.haskey(options, "y2update")
        file = Ops.get_string(options, "y2update", "")
        if FileUtils.Exists(file)
          Ops.set(current_product, "y2update_path", file)
        else
          ReportMissingFile(file)
        end
      elsif Builtins.haskey(options, "y2update_packages_dir")
        dir = Ops.get_string(options, "y2update_packages_dir", "")
        if FileUtils.Exists(dir)
          out = Convert.to_map(
            SCR.Execute(
              path(".target.bash_output"),
              Builtins.sformat("ls -A1 %1/*.rpm 2>/dev/null", dir)
            )
          )
          Ops.set(
            current_product,
            "y2update_packages",
            Builtins.filter(
              Builtins.splitstring(Ops.get_string(out, "stdout", ""), "\n")
            ) { |f| f != "" }
          )
        else
          ReportMissingDir(dir)
        end
      end
      Ops.set(
        current_product,
        "changelog",
        Builtins.haskey(options, "changelog")
      )

      Ops.set(current_product, "generate_release_package", true)
      if Builtins.haskey(options, "no_release_package")
        Ops.set(current_product, "generate_release_package", false)
      end
      if !Builtins.haskey(options, "do_not_sign")
        current_product = Builtins.union(current_product, ParseGPGData(options))
      end
      if !FileUtils.Exists(
          Ops.get_string(current_product, "base_output_path", "")
        )
        SCR.Execute(
          path(".target.mkdir"),
          Ops.get_string(current_product, "base_output_path", "")
        )
      end
      AddOnCreator.current_product = deep_copy(current_product)
      AddOnCreator.selected_product = -1 # new product
      AddOnCreator.CommitCurrentProduct

      return true if Builtins.haskey(options, "do_not_build")

      # now, build the product that was added last: current product data
      # must be initialized again:
      AddOnCreator.current_product = Ops.get(
        AddOnCreator.add_on_products,
        Ops.subtract(Builtins.size(AddOnCreator.add_on_products), 1),
        {}
      )
      # fill again other global values cleared by CommitCurrentProduct
      AddOnCreator.SelectProduct(AddOnCreator.current_product)

      AddOnCreator.BuildAddOn
    end

    # Command line handler for creating new add-on from scratch
    def CreateAddOn(options)
      options = deep_copy(options)
      AddOnCreator.clone = false
      rpm_dir = Ops.get_string(options, "rpm_dir", "")
      if rpm_dir == ""
        # error message
        Report.Error(_("Path to directory with packages is missing."))
        return false
      end
      if Builtins.substring(rpm_dir, Ops.subtract(Builtins.size(rpm_dir), 1), 1) != "/"
        rpm_dir = Ops.add(rpm_dir, "/")
      end
      AddOnCreator.current_product = { "rpm_path" => rpm_dir }
      if !Builtins.haskey(options, "content")
        # error message
        Report.Error(_("Path to content file is missing."))
        return false
      end
      AddOnCreator.FillContentDefaults
      Create(options)
    end

    # Command line handler for clonig existing add-on
    def CloneAddOn(options)
      options = deep_copy(options)
      AddOnCreator.clone = true
      AddOnCreator.import_path = Ops.get_string(options, "existing", "")
      if AddOnCreator.import_path == ""
        # error message
        Report.Error(_("Path to existing Add-On is missing."))
        return false
      end
      AddOnCreator.generate_descriptions = Builtins.haskey(
        options,
        "generate_descriptions"
      )
      AddOnCreator.ImportExistingProduct(AddOnCreator.import_path)
      AddOnCreator.FillContentDefaults # TODO not necessary when content is provided?
      Create(options)
    end

    # Command line handler for signing existing Add-On
    def SignAddOn(options)
      options = deep_copy(options)
      AddOnCreator.only_sign_product = false
      if !Builtins.haskey(options, "addon_dir")
        # error message
        Report.Error(_("Path to directory with Add-On is missing."))
        return false
      else
        Ops.set(
          AddOnCreator.current_product,
          "base_output_path",
          Ops.get_string(options, "addon_dir", "")
        )
      end

      # we need to import same data from existing add-on (e.g. for iso name)
      AddOnCreator.ImportExistingProduct(
        Ops.get_string(options, "addon_dir", "")
      )
      AddOnCreator.FillContentDefaults

      current_product = deep_copy(AddOnCreator.current_product)

      current_product = Builtins.union(current_product, ParseGPGData(options))
      current_product = Builtins.union(current_product, ParseISOData(options))
      AddOnCreator.only_sign_product = true
      AddOnCreator.current_product = deep_copy(current_product)
      AddOnCreator.BuildAddOn
      false 
      # no write needed (configs were not modified, or there was only one-time
      # modification: iso, gpg info)
    end

    # Command line handler for listing existing Add-On configurations
    def ListAddOns(options)
      options = deep_copy(options)
      add_on_products = deep_copy(AddOnCreator.add_on_products)

      i = 1
      Builtins.foreach(add_on_products) do |add_on|
        cont = Ops.get_map(add_on, "content_map", {})
        # command line summary, %1 is order, %2 product name
        CommandLine.Print(
          Builtins.sformat(
            _("(%1) Product Name: %2"),
            i,
            Ops.get_string(cont, "NAME", "")
          )
        )
        # command line summary
        CommandLine.Print(
          Builtins.sformat(
            _("\tVersion: %1"),
            Ops.get_string(cont, "VERSION", "")
          )
        )
        # command line summary
        CommandLine.Print(
          Builtins.sformat(
            _("\tInput directory: %1"),
            Ops.get_string(add_on, "rpm_path", "")
          )
        )
        CommandLine.Print(
          Builtins.sformat(
            _("\tOutput directory: %1"),
            Ops.get_string(add_on, "base_output_path", "")
          )
        )
        if Ops.get_map(add_on, "patterns", {}) != {}
          # command line summary, %1 is comma-separated list
          CommandLine.Print(
            Builtins.sformat(
              _("\tPatterns: %1"),
              Builtins.mergestring(
                Builtins.maplist(Ops.get_map(add_on, "patterns", {})) do |pat, p|
                  pat
                end,
                ", "
              )
            )
          )
        end
        i = Ops.add(i, 1)
      end
      false # no write needed
    end

    # Command line handler for building new addon
    def BuildAddOnHandler(options)
      options = deep_copy(options)
      add_on_products = deep_copy(AddOnCreator.add_on_products)
      if Builtins.size(add_on_products) == 0
        # command line message, do not translate 'create', 'clone'
        Report.Error(
          _(
            "There is no add-on product configuration present. Create a new one using the 'create' or 'clone' commands."
          )
        )
        return false
      end
      number = Ops.get_integer(options, "number", 0)
      if Ops.less_than(number, 1)
        if Builtins.size(add_on_products) == 1
          number = 0
        else
          # error message
          Report.Error(_("Specify the add-on product to build."))
          return false
        end
      end
      # !!! numbers are shown starting from 1, list is indexed from 0 !!!
      product = Ops.get(add_on_products, Ops.subtract(number, 1), {})

      product = Builtins.union(product, ParseISOData(options))
      # if the product should be signed (based on config) ParseGPGData should
      # take care of asking for password
      if Ops.get_boolean(product, "ask_for_passphrase", false) &&
          !Builtins.haskey(options, "gpg_key")
        Ops.set(options, "gpg_key", Ops.get_string(product, "gpg_key", ""))
      end
      product = Builtins.union(product, ParseGPGData(options))

      # only set "generate" when requested, otherwise the saved info is used
      if Builtins.haskey(options, "changelog")
        Ops.set(product, "changelog", true)
      end

      # CLI option could replace the saved one
      if Builtins.haskey(options, "no_release_package")
        Ops.set(product, "generate_release_package", false)
      end

      AddOnCreator.SelectProduct(product)

      AddOnCreator.PrepareBuild
      AddOnCreator.BuildAddOn
      false 
      # no write needed (configs were not modified, or there was only one-time
      # modification: iso, generated)
    end

    # Command line handler for deleting addon config
    def DeleteAddOn(options)
      options = deep_copy(options)
      add_on_products = deep_copy(AddOnCreator.add_on_products)
      if Builtins.size(add_on_products) == 0
        # command line message
        Report.Error(_("There is no add-on product configuration present."))
        return false
      end
      number = Ops.get_integer(options, "number", 0)
      if Ops.less_than(number, 1)
        # error message
        Report.Error(
          _("Specify the add-on product configuration that should be deleted.")
        )
        return false
      end
      # !!! numbers are shown starting from 1, list is indexed from 0 !!!
      AddOnCreator.add_on_products = Builtins.remove(
        add_on_products,
        Ops.subtract(number, 1)
      )
      true
    end
  end
end

Yast::AddOnCreatorClient.new.main
