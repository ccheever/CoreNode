/**
 * Creates the TTYWrap constructor function.
 */
(function(NativeTTYWrap) {
  function TTYWrap(fd, readable) {
    if (fd < 0) {
      throw new Error('Invalid file descriptor (' + fd + ')');
    }
    return NativeTTYWrap.newTTYWrap(fd, readable);
  }

  return TTYWrap;
})
