package S12S::Meeting;

use MongoDBI::Document;

store 'meetings';

key 'division', is_str, is_req;
key 'time', is_str, is_req;
key 'openclosed', is_str, is_req;
key 'meetingname', is_str, is_req;
key 'address', is_str, is_req;
key 'notedisp', is_str, is_req;
key 'dayofweek', is_str, is_req;
1;
