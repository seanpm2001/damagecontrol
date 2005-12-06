require File.dirname(__FILE__) + '/../test_helper'
require 'build_result_mailer'

class BuildResultMailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end
  
  def test_should_render_email_with_changed_files
    @expected.subject = "project_1: fixed build (commit by aslak)"

    mail = BuildResultMailer.create_build_result(
      "nah@not.real", 
      "dcontrol@damagecontrol.buildpatterns.com", 
      builds(:build_1), 
      "dummy stdout tail",
      "dummy stderr tail"
    )
    assert_equal(@expected.subject, mail.subject)
    assert_match(/README/, mail.body)
    assert_match(/config\/boot\.rb/, mail.body)
    assert_match(/dummy stdout tail/, mail.body)
    assert_match(/dummy stderr tail/, mail.body)
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/build_result_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
