
exports.data = [
	{
		"input" : "",
		"output" : "9c1185a5c5e9fc54612808977ee8f548b2258d31"
	},{
		"input" : "a",
		"output" : "0bdc9d2d256b3ee9daae347be6f4dc835a467ffe"
	},
	{
		"input" : "abc",
		"output" : "8eb208f7e05d987a9b044a8e98c6b087f15a0bfc"
	},
	{
		"input" : "message digest",
		"output" : "5d0689ef49d2fae572b881b123a85ffa21595f36"
	},
  {
  	"input" : "abcdefghijklmnopqrstuvwxyz", 
  	"output" : "f71c27109c692c1b56bbdceb5b9d2865b3708dbc"
	},
	{
		"input" : "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		"output" : "12a053384a9c0c88e405a06c27dcf49ada62eb2b"
	},
	{
		"input" : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
		"output" : "b0e20b6e3116640286ed3a87a5713079b21f5189"
	},
	{
		"input" : ("1234567890" for [0...8]).join(''),
		"output" : "9b752e45573d4b39f4dbd3323cab82bf63326bfb"
	},
	{
		"input" : ("a" for [0...1000000]).join(''),
		"output" : "52783243c1697bdbe16d37f97f68f08325dc1528"
	}]

