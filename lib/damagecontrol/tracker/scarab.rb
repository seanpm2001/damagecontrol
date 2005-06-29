module DamageControl
  module Tracker
    class Scarab < Base
      register self

      ann :description => "Base URL", :tip => "The URL of the Scarab installation."
      attr_accessor :baseurl

      ann :description => "Scarab Module", :tip => "The Scarab Module key."
      attr_accessor :module_key

      def initialize(baseurl="http://scarab.org/", module_key="")
        @baseurl, @module_key = baseurl, module_key
      end

      def name
        "Scarab"
      end

      def url
        baseurl
      end

      def highlight(s)
        url = RSCM::PathConverter.ensure_trailing_slash(baseurl)
        if (url)
          htmlize(s.gsub(/(#{module_key}[0-9]+)/, "<a href=\"#{url}issues/id/\\1\">\\1</a>"))
        else
          htmlize(s)
        end
      end
    end
  end
end