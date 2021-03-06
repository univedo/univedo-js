univedo = require('../dist/univedo.js').univedo
assert = require 'assert'

String.prototype.b = ->
  buf = new ArrayBuffer(@length)
  bufView = new Uint8Array(buf)
  for i in [0..@length-1]
    bufView[i] = @charCodeAt(i)
  buf

describe 'cbor', ->
  it 'reads simple', ->
    assert.equal new univedo.Message("\xf6".b()).shift(), null, 'reads null'
    assert.equal new univedo.Message("\xf5".b()).shift(), true, 'reads true'
    assert.equal new univedo.Message("\xf4".b()).shift(), false, 'reads false'

  it 'reads integers', ->
    assert.equal new univedo.Message("\x18\x2a".b()).shift(), 42, 'reads uint'
    assert.equal new univedo.Message("\x18\x64".b()).shift(), 100, 'reads uint'
    assert.equal new univedo.Message("\x1a\x00\x0f\x42\x40".b()).shift(), 1000000, 'reads uint'
    assert.equal new univedo.Message("\x20".b()).shift(), -1, 'reads nint'
    assert.equal new univedo.Message("\x38\x63".b()).shift(), -100, 'reads nint'
    assert.equal new univedo.Message("\x39\x03\xe7".b()).shift(), -1000, 'reads nint'

  it 'reads floats', ->
    assert.equal new univedo.Message("\xfa\x47\xc3\x50\x00".b()).shift(), 100000.0, 'reads floats'
    assert.equal new univedo.Message("\xfb\x3f\xf1\x99\x99\x99\x99\x99\x9a".b()).shift(), 1.1, 'reads floats'

  it 'reads strings', ->
    assert.deepEqual new univedo.Message("\x46foobar".b()).shift(), "foobar".b(), 'reads blobs'
    assert.equal new univedo.Message("\x66foobar".b()).shift(), "foobar", 'reads strings'
    assert.deepEqual new univedo.Message("\x67f\xc3\xb6obar".b()).shift(), "föobar", 'reads utf8strings'

  it 'reads collections', ->
    assert.deepEqual new univedo.Message("\x82\x63foo\x63bar".b()).shift(), ["foo", "bar"], 'reads arrays'
    assert.deepEqual new univedo.Message("\xa2\x63bar\x02\x63foo\x01".b()).shift(), {foo: 1, bar: 2}, 'reads maps'

  it 'reads times', ->
    assert.deepEqual new univedo.Message("\xc0\x74\x32\x30\x31\x33\x2d\x30\x33\x2d\x32\x31\x54\x32\x30\x3a\x30\x34\x3a\x30\x30\x5a".b()).shift(), new Date("2013-03-21T20:04:00Z"), 'reads datetimes'

  it 'reads uuids', ->
    assert.equal new univedo.Message("\xd8\x25\x50\xD5\x06\x81\xAE\xB2\xC1\x49\x4B\xB2\x6E\x7F\xA4\xF7\xEE\x61\x37".b()).shift(), "d50681ae-b2c1-494b-b26e-7fa4f7ee6137", 'reads uuids'

  it 'reads records', ->
    assert.equal new univedo.Message("\xd8\x27\x18\x2a".b()).shift(), 42, 'reads record'

  it 'reads remote objects', ->
    ro_callback = (arr) -> arr
    assert.deepEqual new univedo.Message("\xd8\x1b\x82\x70\x63om.univedo.test\x18\x2a".b(), ro_callback).shift(), ["com.univedo.test", 42]

  it 'sends simple', ->
    assert.deepEqual new univedo.Message().send(null), "\xf6".b(), 'sends null'
    assert.deepEqual new univedo.Message().send(true), "\xf5".b(), 'sends true'
    assert.deepEqual new univedo.Message().send(false), "\xf4".b(), 'sends false'

  it 'sends integers', ->
    assert.deepEqual new univedo.Message().send(1), "\x01".b(), 'sends uint'
    assert.deepEqual new univedo.Message().send(42), "\x18\x2a".b(), 'sends uint'
    assert.deepEqual new univedo.Message().send(100), "\x18\x64".b(), 'sends uint'
    assert.deepEqual new univedo.Message().send(1000000), "\x1a\x00\x0f\x42\x40".b(), 'sends uint'
    assert.deepEqual new univedo.Message().send(-1), "\x20".b(), 'sends nint'
    assert.deepEqual new univedo.Message().send(-100), "\x38\x63".b(), 'sends nint'
    assert.deepEqual new univedo.Message().send(-1000), "\x39\x03\xe7".b(), 'sends nint'

  it 'sends floats', ->
    assert.deepEqual new univedo.Message().send(1.1), "\xfb\x3f\xf1\x99\x99\x99\x99\x99\x9a".b(), 'sends float32'
    assert.deepEqual new univedo.Message().send(1.0e+300), "\xfb\x7e\x37\xe4\x3c\x88\x00\x75\x9c".b(), 'sends float64'

  it 'sends strings', ->
    assert.deepEqual new univedo.Message().send("foobar".b()), "\x46foobar".b(), 'sends blobs'
    assert.deepEqual new univedo.Message().send("foobar"), "\x66foobar".b(), 'sends strings'
    assert.deepEqual new univedo.Message().send("föobar"), "\x67f\xc3\xb6obar".b(), 'sends utf8strings'

  it 'sends collections', ->
    assert.deepEqual new univedo.Message().send(["foo", "bar"]), "\x82\x63foo\x63bar".b(), 'sends arrays'
    # The exact order of keys in an object is undefined, but this does the job as of node v0.10.24
    assert.deepEqual new univedo.Message().send({foo: 1, bar: 2}), "\xa2\x63foo\x01\x63bar\x02".b(), 'sends maps'

  it 'sends times', ->
    assert.deepEqual new univedo.Message().send(new Date("2013-03-21T20:04:00Z")), "\xc0\x78\x18\x32\x30\x31\x33\x2d\x30\x33\x2d\x32\x31\x54\x32\x30\x3a\x30\x34\x3a\x30\x30.000\x5a".b(), 'sends datetimes'

  it 'sends multiple', ->
    m = new univedo.Message()
    m.send("foobar")
    m.send(42)
    assert.deepEqual m.sendBuffer, "\x66foobar\x18\x2a".b(), "sends multiple values"
