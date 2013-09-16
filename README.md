# node-triplesec

A CommonJS module for symmetric key encryption of smallish secrets

## How to install

```sh
npm install triplesec
```

## How to Use

### One-shot Mode

```coffeescript
{encrypt, decrypt} = require 'triplesec'

key = new Buffer 'top-secret-pw'
pt1 = new Buffer 'the secret!'
encrypt { key, input : pt1 }, (err, ciphtertext) ->
	decrypt { key, input : ciphertext }, (err, pt2) ->
		console.log "Right back the start! #{pt1} is #{pt2}"
```