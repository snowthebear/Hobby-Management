/* This file was generated by upb_generator from the input file:
 *
 *     xds/annotations/v3/status.proto
 *
 * Do not edit -- your changes will be discarded when the file is
 * regenerated. */

#ifndef XDS_ANNOTATIONS_V3_STATUS_PROTO_UPB_H_
#define XDS_ANNOTATIONS_V3_STATUS_PROTO_UPB_H_

#include "upb/generated_code_support.h"

#include "xds/annotations/v3/status.upb_minitable.h"

#include "google/protobuf/descriptor.upb_minitable.h"

// Must be last.
#include "upb/port/def.inc"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct xds_annotations_v3_FileStatusAnnotation xds_annotations_v3_FileStatusAnnotation;
typedef struct xds_annotations_v3_MessageStatusAnnotation xds_annotations_v3_MessageStatusAnnotation;
typedef struct xds_annotations_v3_FieldStatusAnnotation xds_annotations_v3_FieldStatusAnnotation;
typedef struct xds_annotations_v3_StatusAnnotation xds_annotations_v3_StatusAnnotation;
struct google_protobuf_FieldOptions;
struct google_protobuf_FileOptions;
struct google_protobuf_MessageOptions;

typedef enum {
  xds_annotations_v3_UNKNOWN = 0,
  xds_annotations_v3_FROZEN = 1,
  xds_annotations_v3_ACTIVE = 2,
  xds_annotations_v3_NEXT_MAJOR_VERSION_CANDIDATE = 3
} xds_annotations_v3_PackageVersionStatus;



/* xds.annotations.v3.FileStatusAnnotation */

UPB_INLINE xds_annotations_v3_FileStatusAnnotation* xds_annotations_v3_FileStatusAnnotation_new(upb_Arena* arena) {
  return (xds_annotations_v3_FileStatusAnnotation*)_upb_Message_New(&xds__annotations__v3__FileStatusAnnotation_msg_init, arena);
}
UPB_INLINE xds_annotations_v3_FileStatusAnnotation* xds_annotations_v3_FileStatusAnnotation_parse(const char* buf, size_t size, upb_Arena* arena) {
  xds_annotations_v3_FileStatusAnnotation* ret = xds_annotations_v3_FileStatusAnnotation_new(arena);
  if (!ret) return NULL;
  if (upb_Decode(buf, size, ret, &xds__annotations__v3__FileStatusAnnotation_msg_init, NULL, 0, arena) != kUpb_DecodeStatus_Ok) {
    return NULL;
  }
  return ret;
}
UPB_INLINE xds_annotations_v3_FileStatusAnnotation* xds_annotations_v3_FileStatusAnnotation_parse_ex(const char* buf, size_t size,
                           const upb_ExtensionRegistry* extreg,
                           int options, upb_Arena* arena) {
  xds_annotations_v3_FileStatusAnnotation* ret = xds_annotations_v3_FileStatusAnnotation_new(arena);
  if (!ret) return NULL;
  if (upb_Decode(buf, size, ret, &xds__annotations__v3__FileStatusAnnotation_msg_init, extreg, options, arena) !=
      kUpb_DecodeStatus_Ok) {
    return NULL;
  }
  return ret;
}
UPB_INLINE char* xds_annotations_v3_FileStatusAnnotation_serialize(const xds_annotations_v3_FileStatusAnnotation* msg, upb_Arena* arena, size_t* len) {
  char* ptr;
  (void)upb_Encode(msg, &xds__annotations__v3__FileStatusAnnotation_msg_init, 0, arena, &ptr, len);
  return ptr;
}
UPB_INLINE char* xds_annotations_v3_FileStatusAnnotation_serialize_ex(const xds_annotations_v3_FileStatusAnnotation* msg, int options,
                                 upb_Arena* arena, size_t* len) {
  char* ptr;
  (void)upb_Encode(msg, &xds__annotations__v3__FileStatusAnnotation_msg_init, options, arena, &ptr, len);
  return ptr;
}
UPB_INLINE void xds_annotations_v3_FileStatusAnnotation_clear_work_in_progress(xds_annotations_v3_FileStatusAnnotation* msg) {
  const upb_MiniTableField field = {1, 0, 0, kUpb_NoSub, 8, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_1Byte << kUpb_FieldRep_Shift)};
  _upb_Message_ClearNonExtensionField(msg, &field);
}
UPB_INLINE bool xds_annotations_v3_FileStatusAnnotation_work_in_progress(const xds_annotations_v3_FileStatusAnnotation* msg) {
  bool default_val = false;
  bool ret;
  const upb_MiniTableField field = {1, 0, 0, kUpb_NoSub, 8, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_1Byte << kUpb_FieldRep_Shift)};
  _upb_Message_GetNonExtensionField(msg, &field, &default_val, &ret);
  return ret;
}

UPB_INLINE void xds_annotations_v3_FileStatusAnnotation_set_work_in_progress(xds_annotations_v3_FileStatusAnnotation *msg, bool value) {
  const upb_MiniTableField field = {1, 0, 0, kUpb_NoSub, 8, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_1Byte << kUpb_FieldRep_Shift)};
  _upb_Message_SetNonExtensionField(msg, &field, &value);
}

/* xds.annotations.v3.MessageStatusAnnotation */

UPB_INLINE xds_annotations_v3_MessageStatusAnnotation* xds_annotations_v3_MessageStatusAnnotation_new(upb_Arena* arena) {
  return (xds_annotations_v3_MessageStatusAnnotation*)_upb_Message_New(&xds__annotations__v3__MessageStatusAnnotation_msg_init, arena);
}
UPB_INLINE xds_annotations_v3_MessageStatusAnnotation* xds_annotations_v3_MessageStatusAnnotation_parse(const char* buf, size_t size, upb_Arena* arena) {
  xds_annotations_v3_MessageStatusAnnotation* ret = xds_annotations_v3_MessageStatusAnnotation_new(arena);
  if (!ret) return NULL;
  if (upb_Decode(buf, size, ret, &xds__annotations__v3__MessageStatusAnnotation_msg_init, NULL, 0, arena) != kUpb_DecodeStatus_Ok) {
    return NULL;
  }
  return ret;
}
UPB_INLINE xds_annotations_v3_MessageStatusAnnotation* xds_annotations_v3_MessageStatusAnnotation_parse_ex(const char* buf, size_t size,
                           const upb_ExtensionRegistry* extreg,
                           int options, upb_Arena* arena) {
  xds_annotations_v3_MessageStatusAnnotation* ret = xds_annotations_v3_MessageStatusAnnotation_new(arena);
  if (!ret) return NULL;
  if (upb_Decode(buf, size, ret, &xds__annotations__v3__MessageStatusAnnotation_msg_init, extreg, options, arena) !=
      kUpb_DecodeStatus_Ok) {
    return NULL;
  }
  return ret;
}
UPB_INLINE char* xds_annotations_v3_MessageStatusAnnotation_serialize(const xds_annotations_v3_MessageStatusAnnotation* msg, upb_Arena* arena, size_t* len) {
  char* ptr;
  (void)upb_Encode(msg, &xds__annotations__v3__MessageStatusAnnotation_msg_init, 0, arena, &ptr, len);
  return ptr;
}
UPB_INLINE char* xds_annotations_v3_MessageStatusAnnotation_serialize_ex(const xds_annotations_v3_MessageStatusAnnotation* msg, int options,
                                 upb_Arena* arena, size_t* len) {
  char* ptr;
  (void)upb_Encode(msg, &xds__annotations__v3__MessageStatusAnnotation_msg_init, options, arena, &ptr, len);
  return ptr;
}
UPB_INLINE void xds_annotations_v3_MessageStatusAnnotation_clear_work_in_progress(xds_annotations_v3_MessageStatusAnnotation* msg) {
  const upb_MiniTableField field = {1, 0, 0, kUpb_NoSub, 8, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_1Byte << kUpb_FieldRep_Shift)};
  _upb_Message_ClearNonExtensionField(msg, &field);
}
UPB_INLINE bool xds_annotations_v3_MessageStatusAnnotation_work_in_progress(const xds_annotations_v3_MessageStatusAnnotation* msg) {
  bool default_val = false;
  bool ret;
  const upb_MiniTableField field = {1, 0, 0, kUpb_NoSub, 8, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_1Byte << kUpb_FieldRep_Shift)};
  _upb_Message_GetNonExtensionField(msg, &field, &default_val, &ret);
  return ret;
}

UPB_INLINE void xds_annotations_v3_MessageStatusAnnotation_set_work_in_progress(xds_annotations_v3_MessageStatusAnnotation *msg, bool value) {
  const upb_MiniTableField field = {1, 0, 0, kUpb_NoSub, 8, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_1Byte << kUpb_FieldRep_Shift)};
  _upb_Message_SetNonExtensionField(msg, &field, &value);
}

/* xds.annotations.v3.FieldStatusAnnotation */

UPB_INLINE xds_annotations_v3_FieldStatusAnnotation* xds_annotations_v3_FieldStatusAnnotation_new(upb_Arena* arena) {
  return (xds_annotations_v3_FieldStatusAnnotation*)_upb_Message_New(&xds__annotations__v3__FieldStatusAnnotation_msg_init, arena);
}
UPB_INLINE xds_annotations_v3_FieldStatusAnnotation* xds_annotations_v3_FieldStatusAnnotation_parse(const char* buf, size_t size, upb_Arena* arena) {
  xds_annotations_v3_FieldStatusAnnotation* ret = xds_annotations_v3_FieldStatusAnnotation_new(arena);
  if (!ret) return NULL;
  if (upb_Decode(buf, size, ret, &xds__annotations__v3__FieldStatusAnnotation_msg_init, NULL, 0, arena) != kUpb_DecodeStatus_Ok) {
    return NULL;
  }
  return ret;
}
UPB_INLINE xds_annotations_v3_FieldStatusAnnotation* xds_annotations_v3_FieldStatusAnnotation_parse_ex(const char* buf, size_t size,
                           const upb_ExtensionRegistry* extreg,
                           int options, upb_Arena* arena) {
  xds_annotations_v3_FieldStatusAnnotation* ret = xds_annotations_v3_FieldStatusAnnotation_new(arena);
  if (!ret) return NULL;
  if (upb_Decode(buf, size, ret, &xds__annotations__v3__FieldStatusAnnotation_msg_init, extreg, options, arena) !=
      kUpb_DecodeStatus_Ok) {
    return NULL;
  }
  return ret;
}
UPB_INLINE char* xds_annotations_v3_FieldStatusAnnotation_serialize(const xds_annotations_v3_FieldStatusAnnotation* msg, upb_Arena* arena, size_t* len) {
  char* ptr;
  (void)upb_Encode(msg, &xds__annotations__v3__FieldStatusAnnotation_msg_init, 0, arena, &ptr, len);
  return ptr;
}
UPB_INLINE char* xds_annotations_v3_FieldStatusAnnotation_serialize_ex(const xds_annotations_v3_FieldStatusAnnotation* msg, int options,
                                 upb_Arena* arena, size_t* len) {
  char* ptr;
  (void)upb_Encode(msg, &xds__annotations__v3__FieldStatusAnnotation_msg_init, options, arena, &ptr, len);
  return ptr;
}
UPB_INLINE void xds_annotations_v3_FieldStatusAnnotation_clear_work_in_progress(xds_annotations_v3_FieldStatusAnnotation* msg) {
  const upb_MiniTableField field = {1, 0, 0, kUpb_NoSub, 8, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_1Byte << kUpb_FieldRep_Shift)};
  _upb_Message_ClearNonExtensionField(msg, &field);
}
UPB_INLINE bool xds_annotations_v3_FieldStatusAnnotation_work_in_progress(const xds_annotations_v3_FieldStatusAnnotation* msg) {
  bool default_val = false;
  bool ret;
  const upb_MiniTableField field = {1, 0, 0, kUpb_NoSub, 8, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_1Byte << kUpb_FieldRep_Shift)};
  _upb_Message_GetNonExtensionField(msg, &field, &default_val, &ret);
  return ret;
}

UPB_INLINE void xds_annotations_v3_FieldStatusAnnotation_set_work_in_progress(xds_annotations_v3_FieldStatusAnnotation *msg, bool value) {
  const upb_MiniTableField field = {1, 0, 0, kUpb_NoSub, 8, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_1Byte << kUpb_FieldRep_Shift)};
  _upb_Message_SetNonExtensionField(msg, &field, &value);
}

/* xds.annotations.v3.StatusAnnotation */

UPB_INLINE xds_annotations_v3_StatusAnnotation* xds_annotations_v3_StatusAnnotation_new(upb_Arena* arena) {
  return (xds_annotations_v3_StatusAnnotation*)_upb_Message_New(&xds__annotations__v3__StatusAnnotation_msg_init, arena);
}
UPB_INLINE xds_annotations_v3_StatusAnnotation* xds_annotations_v3_StatusAnnotation_parse(const char* buf, size_t size, upb_Arena* arena) {
  xds_annotations_v3_StatusAnnotation* ret = xds_annotations_v3_StatusAnnotation_new(arena);
  if (!ret) return NULL;
  if (upb_Decode(buf, size, ret, &xds__annotations__v3__StatusAnnotation_msg_init, NULL, 0, arena) != kUpb_DecodeStatus_Ok) {
    return NULL;
  }
  return ret;
}
UPB_INLINE xds_annotations_v3_StatusAnnotation* xds_annotations_v3_StatusAnnotation_parse_ex(const char* buf, size_t size,
                           const upb_ExtensionRegistry* extreg,
                           int options, upb_Arena* arena) {
  xds_annotations_v3_StatusAnnotation* ret = xds_annotations_v3_StatusAnnotation_new(arena);
  if (!ret) return NULL;
  if (upb_Decode(buf, size, ret, &xds__annotations__v3__StatusAnnotation_msg_init, extreg, options, arena) !=
      kUpb_DecodeStatus_Ok) {
    return NULL;
  }
  return ret;
}
UPB_INLINE char* xds_annotations_v3_StatusAnnotation_serialize(const xds_annotations_v3_StatusAnnotation* msg, upb_Arena* arena, size_t* len) {
  char* ptr;
  (void)upb_Encode(msg, &xds__annotations__v3__StatusAnnotation_msg_init, 0, arena, &ptr, len);
  return ptr;
}
UPB_INLINE char* xds_annotations_v3_StatusAnnotation_serialize_ex(const xds_annotations_v3_StatusAnnotation* msg, int options,
                                 upb_Arena* arena, size_t* len) {
  char* ptr;
  (void)upb_Encode(msg, &xds__annotations__v3__StatusAnnotation_msg_init, options, arena, &ptr, len);
  return ptr;
}
UPB_INLINE void xds_annotations_v3_StatusAnnotation_clear_work_in_progress(xds_annotations_v3_StatusAnnotation* msg) {
  const upb_MiniTableField field = {1, 0, 0, kUpb_NoSub, 8, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_1Byte << kUpb_FieldRep_Shift)};
  _upb_Message_ClearNonExtensionField(msg, &field);
}
UPB_INLINE bool xds_annotations_v3_StatusAnnotation_work_in_progress(const xds_annotations_v3_StatusAnnotation* msg) {
  bool default_val = false;
  bool ret;
  const upb_MiniTableField field = {1, 0, 0, kUpb_NoSub, 8, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_1Byte << kUpb_FieldRep_Shift)};
  _upb_Message_GetNonExtensionField(msg, &field, &default_val, &ret);
  return ret;
}
UPB_INLINE void xds_annotations_v3_StatusAnnotation_clear_package_version_status(xds_annotations_v3_StatusAnnotation* msg) {
  const upb_MiniTableField field = {2, 4, 0, kUpb_NoSub, 5, (int)kUpb_FieldMode_Scalar | (int)kUpb_LabelFlags_IsAlternate | ((int)kUpb_FieldRep_4Byte << kUpb_FieldRep_Shift)};
  _upb_Message_ClearNonExtensionField(msg, &field);
}
UPB_INLINE int32_t xds_annotations_v3_StatusAnnotation_package_version_status(const xds_annotations_v3_StatusAnnotation* msg) {
  int32_t default_val = 0;
  int32_t ret;
  const upb_MiniTableField field = {2, 4, 0, kUpb_NoSub, 5, (int)kUpb_FieldMode_Scalar | (int)kUpb_LabelFlags_IsAlternate | ((int)kUpb_FieldRep_4Byte << kUpb_FieldRep_Shift)};
  _upb_Message_GetNonExtensionField(msg, &field, &default_val, &ret);
  return ret;
}

UPB_INLINE void xds_annotations_v3_StatusAnnotation_set_work_in_progress(xds_annotations_v3_StatusAnnotation *msg, bool value) {
  const upb_MiniTableField field = {1, 0, 0, kUpb_NoSub, 8, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_1Byte << kUpb_FieldRep_Shift)};
  _upb_Message_SetNonExtensionField(msg, &field, &value);
}
UPB_INLINE void xds_annotations_v3_StatusAnnotation_set_package_version_status(xds_annotations_v3_StatusAnnotation *msg, int32_t value) {
  const upb_MiniTableField field = {2, 4, 0, kUpb_NoSub, 5, (int)kUpb_FieldMode_Scalar | (int)kUpb_LabelFlags_IsAlternate | ((int)kUpb_FieldRep_4Byte << kUpb_FieldRep_Shift)};
  _upb_Message_SetNonExtensionField(msg, &field, &value);
}

UPB_INLINE bool xds_annotations_v3_has_file_status(const struct google_protobuf_FileOptions* msg) {
  return _upb_Message_HasExtensionField(msg, &xds_annotations_v3_file_status_ext);
}
UPB_INLINE void xds_annotations_v3_clear_file_status(struct google_protobuf_FileOptions* msg) {
  _upb_Message_ClearExtensionField(msg, &xds_annotations_v3_file_status_ext);
}
UPB_INLINE const xds_annotations_v3_FileStatusAnnotation* xds_annotations_v3_file_status(const struct google_protobuf_FileOptions* msg) {
  const upb_MiniTableExtension* ext = &xds_annotations_v3_file_status_ext;
  UPB_ASSUME(!upb_IsRepeatedOrMap(&ext->field));
  UPB_ASSUME(_upb_MiniTableField_GetRep(&ext->field) == kUpb_FieldRep_8Byte);
  const xds_annotations_v3_FileStatusAnnotation* default_val = NULL;
  const xds_annotations_v3_FileStatusAnnotation* ret;
  _upb_Message_GetExtensionField(msg, ext, &default_val, &ret);
  return ret;
}
UPB_INLINE void xds_annotations_v3_set_file_status(struct google_protobuf_FileOptions* msg, const xds_annotations_v3_FileStatusAnnotation* val, upb_Arena* arena) {
  const upb_MiniTableExtension* ext = &xds_annotations_v3_file_status_ext;
  UPB_ASSUME(!upb_IsRepeatedOrMap(&ext->field));
  UPB_ASSUME(_upb_MiniTableField_GetRep(&ext->field) == kUpb_FieldRep_8Byte);
  bool ok = _upb_Message_SetExtensionField(msg, ext, &val, arena);
  UPB_ASSERT(ok);
}
UPB_INLINE bool xds_annotations_v3_has_message_status(const struct google_protobuf_MessageOptions* msg) {
  return _upb_Message_HasExtensionField(msg, &xds_annotations_v3_message_status_ext);
}
UPB_INLINE void xds_annotations_v3_clear_message_status(struct google_protobuf_MessageOptions* msg) {
  _upb_Message_ClearExtensionField(msg, &xds_annotations_v3_message_status_ext);
}
UPB_INLINE const xds_annotations_v3_MessageStatusAnnotation* xds_annotations_v3_message_status(const struct google_protobuf_MessageOptions* msg) {
  const upb_MiniTableExtension* ext = &xds_annotations_v3_message_status_ext;
  UPB_ASSUME(!upb_IsRepeatedOrMap(&ext->field));
  UPB_ASSUME(_upb_MiniTableField_GetRep(&ext->field) == kUpb_FieldRep_8Byte);
  const xds_annotations_v3_MessageStatusAnnotation* default_val = NULL;
  const xds_annotations_v3_MessageStatusAnnotation* ret;
  _upb_Message_GetExtensionField(msg, ext, &default_val, &ret);
  return ret;
}
UPB_INLINE void xds_annotations_v3_set_message_status(struct google_protobuf_MessageOptions* msg, const xds_annotations_v3_MessageStatusAnnotation* val, upb_Arena* arena) {
  const upb_MiniTableExtension* ext = &xds_annotations_v3_message_status_ext;
  UPB_ASSUME(!upb_IsRepeatedOrMap(&ext->field));
  UPB_ASSUME(_upb_MiniTableField_GetRep(&ext->field) == kUpb_FieldRep_8Byte);
  bool ok = _upb_Message_SetExtensionField(msg, ext, &val, arena);
  UPB_ASSERT(ok);
}
UPB_INLINE bool xds_annotations_v3_has_field_status(const struct google_protobuf_FieldOptions* msg) {
  return _upb_Message_HasExtensionField(msg, &xds_annotations_v3_field_status_ext);
}
UPB_INLINE void xds_annotations_v3_clear_field_status(struct google_protobuf_FieldOptions* msg) {
  _upb_Message_ClearExtensionField(msg, &xds_annotations_v3_field_status_ext);
}
UPB_INLINE const xds_annotations_v3_FieldStatusAnnotation* xds_annotations_v3_field_status(const struct google_protobuf_FieldOptions* msg) {
  const upb_MiniTableExtension* ext = &xds_annotations_v3_field_status_ext;
  UPB_ASSUME(!upb_IsRepeatedOrMap(&ext->field));
  UPB_ASSUME(_upb_MiniTableField_GetRep(&ext->field) == kUpb_FieldRep_8Byte);
  const xds_annotations_v3_FieldStatusAnnotation* default_val = NULL;
  const xds_annotations_v3_FieldStatusAnnotation* ret;
  _upb_Message_GetExtensionField(msg, ext, &default_val, &ret);
  return ret;
}
UPB_INLINE void xds_annotations_v3_set_field_status(struct google_protobuf_FieldOptions* msg, const xds_annotations_v3_FieldStatusAnnotation* val, upb_Arena* arena) {
  const upb_MiniTableExtension* ext = &xds_annotations_v3_field_status_ext;
  UPB_ASSUME(!upb_IsRepeatedOrMap(&ext->field));
  UPB_ASSUME(_upb_MiniTableField_GetRep(&ext->field) == kUpb_FieldRep_8Byte);
  bool ok = _upb_Message_SetExtensionField(msg, ext, &val, arena);
  UPB_ASSERT(ok);
}
#ifdef __cplusplus
}  /* extern "C" */
#endif

#include "upb/port/undef.inc"

#endif  /* XDS_ANNOTATIONS_V3_STATUS_PROTO_UPB_H_ */
