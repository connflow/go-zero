syntax = "proto3";

package {{.package}};

import "google/api/annotations.proto";
import "google/api/client.proto";
import "google/api/field_behavior.proto";
import "google/protobuf/descriptor.proto";
import "google/protobuf/field_mask.proto";
import "google/protobuf/timestamp.proto";
import "validate/validate.proto";

option go_package="./{{.package}}";

// Common type

// IdRequest for simple query or delete indicator
message IdRequest {
  string id = 1 [(validate.rules).string = {min_len: 20, max_len: 40}];
}

message ResourceIdRequest {
  string account_id = 1 [(validate.rules).string = {min_len: 20, max_len: 40}];
  string id = 2 [(validate.rules).string = {min_len: 20, max_len: 40}];
}

// Empty use for empty response 
message Empty {

}

// QueryInfoRequest is Common list query request
message QueryInfoRequest {
  int64 page_size = 1 [(validate.rules).int64 = {lte: 1000}];
  string page_token = 2;
  string filter = 3;
  string sorting = 4;
  bool total = 5; 
}

message ResourceQueryInfoRequest {
  int64 page_size = 1 [(validate.rules).int64 = {lte: 1000}];
  string page_token = 2;
  string filter = 3;
  string sorting = 4;
  bool total = 5;
  string account_id = 6 [(validate.rules).string = {min_len: 20, max_len: 40}];
}

// BaseResponse is Common response for update and modify
message BaseResponse {
  string message = 1;
}

// {{.serviceName}} message model
message {{.serviceName}} {
  string id = 1;
  string name = 2[(validate.rules).string = {ignore_empty: true, min_len: 5, max_len: 12}];
  google.protobuf.Timestamp create_time = 3;
  google.protobuf.Timestamp update_time = 4;
}

// List{{.entities}}Response for list {{.entity}} query
message List{{.entities}}Response {
  int64 total_size = 1;
  repeated {{.entity}} data = 2;
  string next_page_token = 3;
}

// Create{{.entity}}Request for create {{.entity}} query
message Create{{.entity}}Request {
  {{.entity}} data = 1 [(validate.rules).message.required = true];
}

// Update{{.entity}}Request for update {{.entity}} query
message Update{{.entity}}Request {
  {{.entity}} data = 1 [(validate.rules).message.required = true];
  google.protobuf.FieldMask update_mask = 2 [(google.api.field_behavior) = OPTIONAL];
}

// {{.entity}} service for {{.entity}} operate in manager module
service {{.entity}}s {
  // Get {{.entity}} use {{.entity}} id
  rpc Get{{.entity}}(ResourceIdRequest) returns ({{.entity}}) {
    option (google.api.http) = {
      get: "/v1/manager/{{.entity}}/{id=*}"
    };
    option (google.api.method_signature) = "id";
  };
  // List {{.entities}} support pagequery
  rpc List{{.entities}}(ResourceQueryInfoRequest) returns (List{{.entities}}Response) {
    option (google.api.http) = {
      get: "/v1/manager/{{.entities}}s"
    };
  };
  // Create a {{.entity}} in manager module
  rpc Create{{.entity}}(Create{{.entity}}Request) returns ({{.entity}}) {
    option (google.api.http) = {
      post: "/v1/manager/{{.entity}}s"
    };
  };
  // Update a {{.entity}} in manager module
  rpc Update{{.entity}}(Update{{.entity}}Request) returns (BaseResponse) {
    option (google.api.http) = {
      delete: "/v1/manager/{{.entity}}s/{id=*}"
    };
    option (google.api.method_signature) = "id";
  };
  // Delete a {{.entity}} in manager module
  rpc Delete{{.entity}}(ResourceIdRequest) returns (BaseResponse) {
    option (google.api.http) = {
      delete: "/v1/manager/{{.entity}}s/{id=*}"
    };
    option (google.api.method_signature) = "id";
  };
}
