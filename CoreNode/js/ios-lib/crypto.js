// TODO: Fill this in later
module.exports = {
  randomBytes: function (size, callback) {
    // http://nodejs.org/docs/v0.6.9/api/crypto.html#randomBytes
    b = new Buffer(size);
    for (var i = 0; i < size; ++i) {
      b[i] = Math.random() * 256;
    }
    return b;
  },

  // For window.crypto
  /*
  getRandomValues: function (typedArray) {

  },
  */
}

// For reference:
/*
fibrous-coffee> process.binding('crypto')
{ SecureContext: [Function: SecureContext],
  Connection: [Function: Connection],
  Cipher: [Function],
  Decipher: [Function],
  DiffieHellman: [Function],
  DiffieHellmanGroup: [Function],
  Hmac: [Function],
  Hash: [Function],
  Sign: [Function],
  Verify: [Function],
  PBKDF2: [Function],
  randomBytes: [Function],
  pseudoRandomBytes: [Function],
  getSSLCiphers: [Function],
  getCiphers: [Function],
  getHashes: [Function] }
*/

