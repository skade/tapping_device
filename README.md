# TappingDevice

![GitHub Action](https://github.com/st0012/tapping_device/workflows/Ruby/badge.svg)
[![Gem Version](https://badge.fury.io/rb/tapping_device.svg)](https://badge.fury.io/rb/tapping_device)
[![Maintainability](https://api.codeclimate.com/v1/badges/3e3732a6983785bccdbd/maintainability)](https://codeclimate.com/github/st0012/tapping_device/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/3e3732a6983785bccdbd/test_coverage)](https://codeclimate.com/github/st0012/tapping_device/test_coverage)
[![Open Source Helpers](https://www.codetriage.com/st0012/tapping_device/badges/users.svg)](https://www.codetriage.com/st0012/tapping_device)


## Introduction
`TappingDevice` makes the objects tell you what they do, so you don't need to track them yourself.

#### Contract Tracing For Objects

The concept is very simple. It's basically like [contact tracing](https://en.wikipedia.org/wiki/Contact_tracing) for your Ruby objects. You can use 

- `print_calls(object)` to see what the object does
- `print_traces(object)` to see how the object interacts with other objects (like used as an argument)

Still sounds vague? Let's see some examples:

### `print_calls` To Track Method Calls

In [Discourse](https://github.com/discourse/discourse), it uses the `Guardian` class for authorization (like policy objects). It's barely visible in controller actions, but it does many checks under the hood. Now, let's say we want to know what the `Guadian` would do when a user creates a post; here's the controller action:

```ruby
  def create
    @manager_params = create_params
    @manager_params[:first_post_checks] = !is_api?

    manager = NewPostManager.new(current_user, @manager_params)

    if is_api?
      memoized_payload = DistributedMemoizer.memoize(signature_for(@manager_params), 120) do
        result = manager.perform
        MultiJson.dump(serialize_data(result, NewPostResultSerializer, root: false))
      end

      parsed_payload = JSON.parse(memoized_payload)
      backwards_compatible_json(parsed_payload, parsed_payload['success'])
    else
      result = manager.perform
      json = serialize_data(result, NewPostResultSerializer, root: false)
      backwards_compatible_json(json, result.success?)
    end
  end
```

As you can see, it doesn't even exist in the controller action, which makes tracking it by reading code very hard to do.

But with `TappingDevice`. You can use `print_calls` to show what method calls the object performs

```ruby
  def create
    # you can retrieve the current guardian object by calling guardian in the controller
    print_calls(guardian)
    @manager_params = create_params
   
    # .....
```

Now, if you execute the code, like via tests:

```shell
$ rspec spec/requests/posts_controller_spec.rb:603
```

You can get all the method calls it performs with basically everything you need to know

<img src="https://github.com/st0012/tapping_device/blob/master/images/print_calls.png" alt="image of print_calls output" width="50%">

Let's take a closer look at each entry. Everyone of them contains the method call's
- method name 
- method source class/module
- call site
- arguments
- return value

![explanation of individual entry](https://github.com/st0012/tapping_device/blob/master/images/print_calls%20-%20single%20entry.png)

These are the information you'd have to look up one by one manually (probably with many debug code writing). Now you can get all of them in just one line of code.


### `print_traces` To See The Object's Traces

If you're not interested in what an object does, but what it interacts with other parts of the program, e.g., used as arguments. You can use the `print_traces` helper. Let's see how `Discourse` uses the `manager` object when creating a post

```ruby
  def create
    @manager_params = create_params
    @manager_params[:first_post_checks] = !is_api?
   
    manager = NewPostManager.new(current_user, @manager_params)

    print_traces(manager)
    # .....
```

And after running the test case

```shell
$ rspec spec/requests/posts_controller_spec.rb:603
```

You will see that it performs 2 calls: `perform` and `perform_create_post`. And it's also used as `manager` argument in various of calls of the `NewPostManager` class.

![image of print_traces output](https://github.com/st0012/tapping_device/blob/master/images/print_traces.png)

**You can try these examples on [my fork of discourse](https://github.com/st0012/discourse/tree/demo-for-tapping-device)**


## Installation
Add this line to your application's Gemfile:

```ruby
gem 'tapping_device', group: :development
```

And then execute:

```
$ bundle
```

Or install it directly:

```
$ gem install tapping_device
```

**Depending on the size of your application, `TappingDevice` could harm the performance significantly.  So make sure you don't put it inside the production group**


### Advance Usages & Options 

#### Add Conditions With `.with`

Sometimes we don't need to know all the calls or traces of an object; we just want some of them. In those cases, we can chain the helpers with `.with` to filter the calls/traces.

```ruby
# only prints calls with name matches /foo/
print_calls(object).with do |payload|
  payload.method_name.to_s.match?(/foo/)
end
```

#### `colorize: false`

By default `print_calls` and `print_traces` colorize their output. If you don't want the colors, you can use `colorize: false` to disable it.


```ruby
print_calls(object, colorize: false)
```


#### `inspect: true`

As you might have noticed, all the objects are converted into strings with `#to_s` instead of `#inspect`.  This is because when used on some Rails objects, `#inspect` can generate a significantly larger string than `#to_s`. For example:

``` ruby
post.to_s #=> #<Post:0x00007f89a55201d0>
post.inspect #=> #<Post id: 649, user_id: 3, topic_id: 600, post_number: 1, raw: "Hello world", cooked: "<p>Hello world</p>", created_at: "2020-05-24 08:07:29", updated_at: "2020-05-24 08:07:29", reply_to_post_number: nil, reply_count: 0, quote_count: 0, deleted_at: nil, off_topic_count: 0, like_count: 0, incoming_link_count: 0, bookmark_count: 0, score: nil, reads: 0, post_type: 1, sort_order: 1, last_editor_id: 3, hidden: false, hidden_reason_id: nil, notify_moderators_count: 0, spam_count: 0, illegal_count: 0, inappropriate_count: 0, last_version_at: "2020-05-24 08:07:29", user_deleted: false, reply_to_user_id: nil, percent_rank: 1.0, notify_user_count: 0, like_score: 0, deleted_by_id: nil, edit_reason: nil, word_count: 2, version: 1, cook_method: 1, wiki: false, baked_at: "2020-05-24 08:07:29", baked_version: 2, hidden_at: nil, self_edits: 0, reply_quoted: false, via_email: false, raw_email: nil, public_version: 1, action_code: nil, image_url: nil, locked_by_id: nil, image_upload_id: nil>
```


### Lower-Level Helpers
`print_calls` and `print_traces` aren't the only helpers you can get from `TappingDevice`. They are actually built on top of other helpers, which you can use as well. To know more about them, please check [this page](https://github.com/st0012/tapping_device/wiki/Advance-Usages)


### Related Blog Posts
- [Optimize Your Debugging Process With Object-Oriented Tracing and tapping_device](http://bit.ly/object-oriented-tracing) 
- [Debug Rails issues effectively with tapping_device](https://dev.to/st0012/debug-rails-issues-effectively-with-tappingdevice-c7c)
- [Want to know more about your Rails app? Tap on your objects!](https://dev.to/st0012/want-to-know-more-about-your-rails-app-tap-on-your-objects-bd3)


## Development
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/st0012/tapping_device. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TappingDevice project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/tapping_device/blob/master/CODE_OF_CONDUCT.md).
