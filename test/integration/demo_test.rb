require "test_helper"

# The demo endpoints exist to misbehave. These tests check they misbehave in
# exactly the way the AppSignal walkthrough expects.
class DemoTest < ActionDispatch::IntegrationTest
  setup do
    build_catalogue!
    @rub.reviews.create!(author_name: "A", rating: 5, body: "Great")
    @scarce.reviews.create!(author_name: "B", rating: 3, body: "Fine")
  end

  test "the demo index lists the scenarios" do
    get demo_path
    assert_response :success
    assert_match "AppSignal demo controls", response.body
  end

  test "slow query returns rows" do
    get demo_slow_query_path
    assert_response :success
    assert_match "Slow query complete", response.body
  end

  test "n+1 and optimised render the same product list" do
    get demo_n_plus_one_path
    assert_response :success
    n_plus_one_body = response.body

    get demo_optimised_path
    assert_response :success

    assert_match @rub.name, n_plus_one_body
    assert_match @rub.name, response.body
  end

  test "the error endpoint really raises" do
    assert_raises(DemoController::BarbecueOnFireError) do
      get demo_error_path
    end
  end

  test "the handled error endpoint returns a normal page" do
    get demo_handled_error_path
    assert_response :success
    assert_match "Reported to AppSignal", response.body
  end

  test "background job endpoint enqueues jobs" do
    assert_enqueued_jobs 4 do
      post demo_background_job_path, params: { count: 4 }
    end
    assert_redirected_to demo_path
  end

  test "background job count is clamped" do
    assert_enqueued_jobs 25 do
      post demo_background_job_path, params: { count: 5_000 }
    end
  end

  test "memory hog completes" do
    get demo_memory_hog_path
    assert_response :success
    assert_match "Allocated and discarded", response.body
  end

  test "custom metric endpoint renders whether or not appsignal is active" do
    get demo_custom_metric_path
    assert_response :success
  end
end
