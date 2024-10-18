#include <node_api.h>
#include <stdio.h>
#include <sodium.h>
#include <assert.h>

napi_value print (napi_env env, napi_callback_info info) {
  napi_status status;

  napi_value argv[3];
  size_t argc = 3;

  napi_get_cb_info(env, info, &argc, argv, NULL, NULL);

  if (argc < 3) {
    napi_throw_error(env, "EINVAL", "Too few arguments");
    return NULL;
  }
  
  napi_valuetype valuetype0;
  status = napi_typeof(env, argv[0], &valuetype0);
  assert(status == napi_ok);

  napi_valuetype valuetype1;
  status = napi_typeof(env, argv[1], &valuetype1);
  assert(status == napi_ok);

  napi_valuetype valuetype2;
  status = napi_typeof(env, argv[2], &valuetype2);
  assert(status == napi_ok);

  if (valuetype0 != napi_string || valuetype1 != napi_number || valuetype2 != napi_number) {
    napi_throw_type_error(env, NULL, "Wrong arguments");
    return NULL;
  }

  char value0[1024];
  size_t value0_len;
  status = napi_get_value_string_utf8(env, argv[0], (char *) &value0, 1024, &value0_len);
  assert(status == napi_ok);

  int64_t value1;
  status = napi_get_value_int64(env, argv[1], &value1);
  assert(status == napi_ok);

  int64_t value2;
  status = napi_get_value_int64(env, argv[2], &value2);
  assert(status == napi_ok);

  printf("Value 0: %s\n", value0);
  printf("Value 1: %lld\n", value1);
  printf("Value 2: %lld\n", value2);

  char hashed_password[crypto_pwhash_STRBYTES];
  if (crypto_pwhash_str(hashed_password, value0, value0_len, (size_t)value1, (size_t)value2) != 0) {
    napi_throw_error(env, "EINVAL", "Failed to hash password");
    return NULL;
  }


  napi_value output;
  status = napi_create_string_utf8(env, hashed_password, crypto_pwhash_STRBYTES, &output);
  assert(status == napi_ok);

  return output;
}


napi_value init_all (napi_env env, napi_value exports) {
  napi_value print_fn;
  napi_create_function(env, NULL, 0, print, NULL, &print_fn);
  napi_set_named_property(env, exports, "add", print_fn);
  return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, init_all)