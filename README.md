# verkada-ruby

Verkada API for Ruby

## Usage

```ruby
require_relative './verkada'

verkada = VerkadaAPI::Org.new('123-your-org-id-456', 'YoUrApIkEy789')
verkada.refresh_cameras
camera = verkada.cameras[0]
camera.model       # "CF81-E"
camera.last_online # 2021-01-23 01:23:45 -0800
camera.status      # :live
camera.thumbnail   # "https://verkada.s3.amazonaws.com/v2/abcd/1234.jpg..."
```
