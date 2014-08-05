/**
 * Creates the ContextifyBinding constructor function.
 */
(function(nativeContextifyBinding) {
  nativeContextifyBinding.isContext = nativeContextifyBinding.isContext.bind(nativeContextifyBinding);
  return nativeContextifyBinding;
})
