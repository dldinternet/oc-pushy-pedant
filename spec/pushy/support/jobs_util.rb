# @copyright Copyright 2012 Chef Software, Inc. All Rights Reserved.
#
# This file is provided to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file
# except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#

require 'pushy/support/end_to_end_util'

shared_context "job_body_util" do
  include_context "end_to_end_util"
  let(:valid_datetime) { ->(v) { Time.parse(v) } }

  let(:default_payload) {
    {
      "command" => "sleep 1",
      "nodes" => ["DONKEY"],
      "quorum" => 1,
      "run_timeout" => 3600
    }
  }

  let(:default_result) {
    {
      "command" => "sleep 1",
      "nodes" => {"unavailable" => ["DONKEY"]},
      "id" => /^[0-9a-f]{32}$/,
      "run_timeout" => 3600,
      "status" => "quorum_failed",
      "created_at" => valid_datetime,
      "updated_at" => valid_datetime
    }
  }

  def make_payload(payload, overwrite_variables)
    result = payload
    if (overwrite_variables[:skip_delete])
      overwrite_variables.delete(:skip_delete)
      skip_delete = true
    end
    if (overwrite_variables[:bogus_value])
      overwrite_variables.delete(:bogus_value)
      bogus_value = true
    end
    overwrite_variables.each do |variable,value|
      if value == :delete
        if (!skip_delete)
          result.delete(variable)
        end
      else
        if (result[variable] || bogus_value)
          result[variable] = value
        end
      end
    end
    return result
  end

  def self.fails_with_value(variable, value, bogus = false, pending = false)
    if (pending)
      it "with #{variable} = #{value} it reports 400", :validation, :pending do
      end
    else
      it "with #{variable} = #{value} it reports 400", :validation do
        response = post(api_url("/pushy/jobs"), admin_user,
                        :payload => make_payload(default_payload, variable => value,
                                                 :bogus_value => bogus))
      end
    end
  end

  def self.succeeds_with_value(variable, value, expected_value = nil, pending = false)
    expected_value ||= value
    if (pending)
      it "with #{variable} = #{value} it succeeds", :pending do
      end
    else
      it "with #{variable} = #{value} it succeeds" do
        response = post(api_url("/pushy/jobs"), admin_user,
                        :payload => make_payload(default_payload, variable => value))
        list = JSON.parse(response.body)
        new_job_uri = list["uri"]
        response.should look_like({
                                    :status => 201,
                                    :body_exact => {
                                      "uri" => new_job_uri
                                    }})

        # Sometimes if the test host is experiencing excessive load
        # (or is underpowered), it may take longer for voting to
        # happen and the quorum to fail.  In these cases, tests would
        # fail because the job was still voting when we checked its
        # status.  We aren't really interested in checking transitions
        # here, but the end status, so we'll just wait for the job to
        # reach a terminal state before proceeding with the tests
        wait_for_job_status(new_job_uri, 'quorum_failed')

        # Now we'll get the job and do the comparisons
        response = get(new_job_uri, admin_user)
        response.
          should look_like({
                             :status => 200,
                             :body_exact => make_payload(default_result,
                                                         variable => expected_value,
                                                         :skip_delete => true) })
      end
    end
  end
end
