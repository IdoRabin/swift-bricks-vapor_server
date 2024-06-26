//
// ErrorCodes.js
//
// Autogenerated for Bricks on Vapor / Leaf as JS. on:18/02/2023, 23:21:52
// Autogenerator using transfer_error_codes_to_js.py


// Autogenerated by script
const AppErrorCode = {

    //  - If there is any codes / domains BEFORE http statuses -
    // MAXRANGE: 99
    
    // iana HTTPResponseStatus (in swift-nio)
    // 1xx
	http_stt_continue : {
		code : 100,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:100",
	},
	http_stt_switchingProtocols : {
		code : 101,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:101",
	},
	http_stt_processing : {
		code : 102,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:102",
	},
    // TODO: add '103: Early Hints' when swift-nio upgrades

    // iana HTTPResponseStatus (in swift-nio)
    // 2xx
	http_stt_ok : {
		code : 200,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:200",
	},
	http_stt_created : {
		code : 201,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:201",
	},
	http_stt_accepted : {
		code : 202,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:202",
	},
	http_stt_nonAuthoritativeInformation : {
		code : 203,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:203",
	},
	http_stt_noContent_204 : {
		code : 204,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:204",
	},
	http_stt_resetContent : {
		code : 205,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:205",
	},
	http_stt_partialContent : {
		code : 206,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:206",
	},
	http_stt_multiStatus : {
		code : 207,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:207",
	},
	http_stt_alreadyReported : {
		code : 208,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:208",
	},
	http_stt_imUsed : {
		code : 209,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:209",
	},

    // iana HTTPResponseStatus (in swift-nio)
    // 3xx
	http_stt_multipleChoices : {
		code : 300,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:300",
	},
	http_stt_movedPermanently : {
		code : 301,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:301",
	},
	http_stt_found : {
		code : 302,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:302",
	},
	http_stt_seeOther : {
		code : 303,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:303",
	},
	http_stt_notModified : {
		code : 304,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:304",
	},
	http_stt_useProxy : {
		code : 305,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:305",
	},
	http_stt_temporaryRedirect : {
		code : 306,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:306",
	},
	http_stt_permanentRedirect : {
		code : 307,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:307",
	},

    // iana HTTPResponseStatus (in swift-nio)
    // 4xx
	http_stt_badRequest : {
		code : 400,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:400",
	},
	http_stt_unauthorized:  { // 401
		code : 401,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:401",
	},
	http_stt_paymentRequired:  {   // 402
		code : 402,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:402",
	},
	http_stt_forbidden:  {          // 403
		code : 403,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:403",
	},
	http_stt_notFound:  {           // 404
		code : 404,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:404",
	},
	http_stt_methodNotAllowed:  {     // 405
		code : 405,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:405",
	},
	http_stt_notAcceptable:  {         // 406
		code : 406,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:406",
	},
	http_stt_proxyAuthenticationRequired:  {  // 407
		code : 407,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:407",
	},
	http_stt_requestTimeout:  {             // 408
		code : 408,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:408",
	},
	http_stt_conflict:  {               // 409
		code : 409,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:409",
	},
	http_stt_gone:  {                   // 410
		code : 410,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:410",
	},
	http_stt_lengthRequired:  {         // 411
		code : 411,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:411",
	},
	http_stt_preconditionFailed:  {     // 412
		code : 412,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:412",
	},
	http_stt_payloadTooLarge:  {       // 413
		code : 413,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:413",
	},
	http_stt_uriTooLong:  {             // 414
		code : 414,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:414",
	},
	http_stt_unsupportedMediaType:  {   //  : {
		code : 415,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:415",
	},
	http_stt_rangeNotSatisfiable:  {    // 416 
		code : 416,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:416",
	},
	http_stt_expectationFailed : {
		code : 417,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:417",
	},
	http_stt_imATeapot : {
		code : 418,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:418",
	},
	http_stt_misdirectedRequest : {
		code : 419,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:419",
	},
	http_stt_unprocessableEntity : {
		code : 420,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:420",
	},
	http_stt_locked : {
		code : 421,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:421",
	},
	http_stt_failedDependency : {
		code : 422,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:422",
	},
	http_stt_upgradeRequired : {
		code : 423,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:423",
	},
	http_stt_preconditionRequired : {
		code : 424,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:424",
	},
	http_stt_tooManyRequests : {
		code : 425,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:425",
	},
	http_stt_requestHeaderFieldsTooLarge : {
		code : 426,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:426",
	},
	http_stt_unavailableForLegalReasons : {
		code : 427,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:427",
	},

    // Other names for HTTP status codes Vapor introduced:
    /// Input was syntactically correct, but not semantically (usually failed validations).
    /// requested data not found, while the request URI exists and is valid, and input data is valid and yielded an empty collection of object/s

    // iana HTTPResponseStatus (in swift-nio)
    // 5xx
	http_stt_internalServerError : {
		code : 500,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:500",
	},
	http_stt_notImplemented : {
		code : 501,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:501",
	},
	http_stt_badGateway : {
		code : 502,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:502",
	},
	http_stt_serviceUnavailable : {
		code : 503,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:503",
	},
	http_stt_gatewayTimeout : {
		code : 504,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:504",
	},
	http_stt_httpVersionNotSupported : {
		code : 505,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:505",
	},
	http_stt_variantAlsoNegotiates : {
		code : 506,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:506",
	},
	http_stt_insufficientStorage : {
		code : 507,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:507",
	},
	http_stt_loopDetected : {
		code : 508,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:508",
	},
	http_stt_notExtended : {
		code : 509,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:509",
	},
	http_stt_networkAuthenticationRequired : {
		code : 510,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:510",
	},


    // Cancel
	nceled_by_user : {
		code : 8001,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:8001",
	},
	nceled_by_server : {
		code : 8002,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:8002",
	},
	nceled_by_client : {
		code : 8003,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:8003",
	},
    // MAXRANGE: 8999

    // Misc
	misc_unknown : {
		code : 9000,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9000",
	},
	misc_failed_loading : {
		code : 9001,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9001",
	},
	misc_failed_saving : {
		code : 9002,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9002",
	},
	misc_operation_canceled : {
		code : 9003,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9003",
	},
	misc_failed_creating : {
		code : 9010,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9010",
	},
	misc_failed_removing : {
		code : 9011,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9011",
	},
	misc_failed_inserting : {
		code : 9012,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9012",
	},
	misc_failed_updating : {
		code : 9013,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9013",
	},
	misc_failed_reading : {
		code : 9014,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9014",
	},
	misc_no_permission_for_operation : {
		code : 9020,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9020",
	},
	misc_readonly_permission_for_operation : {
		code : 9021,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9021",
	},
	misc_failed_crypto : {
		code : 9022,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9022",
	},
	misc_failed_parsing : {
		code : 9030,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9030",
	},
	misc_failed_encoding : {
		code : 9031,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9031",
	},
	misc_failed_decoding : {
		code : 9032,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9032",
	},
	misc_failed_validation : {
		code : 9033,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9033",
	},
	misc_already_exists : {
		code : 9034,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:9034",
	},
    // MAXRANGE: 9999
    

    // Web
	web_unknown : {
		code : 1000,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:1000",
	},
	web_internet_connection_error : {
		code : 1003,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:1003",
	},
	web_unexpected_response : {
		code : 1100,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:1100",
	},
    // MAXRANGE: 1200

    // Command
	md_not_allowed_now : {
		code : 1500,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:1500",
	},
	md_failed_execute : {
		code : 1501,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:1501",
	},
	md_failed_undo : {
		code : 1502,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:1502",
	},
    // MAXRANGE: 1600

    // Doc
	doc_unknown : {
		code : 2000,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2000",
	},
	doc_create_new_failed : {
		code : 2010,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2010",
	},
	doc_create_from_template_failed : {
		code : 2011,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2011",
	},
	doc_open_existing_failed : {
		code : 2012,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2012",
	},
	doc_save_failed : {
		code : 2013,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2013",
	},
	doc_load_failed : {
		code : 2014,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2014",
	},
	doc_close_failed : {
		code : 2015,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2015",
	},
	doc_change_failed : {
		code : 2016,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2016",
	},
    // MAXRANGE: 2029

    // Layer
	doc_layer_insert_failed : {
		code : 2030,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2030",
	},
	doc_layer_insert_undo_failed : {
		code : 2031,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2031",
	},
	doc_layer_move_failed : {
		code : 2032,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2032",
	},
	doc_layer_move_undo_failed : {
		code : 2033,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2033",
	},
	doc_layer_delete_failed : {
		code : 2040,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2040",
	},
	doc_layer_delete_undo_failed : {
		code : 2041,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2041",
	},
	doc_layer_already_exists : {
		code : 2050,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2050",
	},
	doc_layer_lock_unlock_failed : {
		code : 2051,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2051",
	},
	doc_layer_select_deselect_failed : {
		code : 2052,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2052",
	},
	doc_layer_search_failed : {
		code : 2060,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2060",
	},
	doc_layer_change_failed : {
		code : 2070,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2070",
	},
    // MAXRANGE: 2090

    // User
	user_login_failed : {
		code : 2501,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2501",
	},
	user_login_failed_no_permission : {
		code : 2502,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2502",
	},
	user_login_failed_bad_credentials : {
		code : 2503,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2503",
	},
	user_login_failed_permissions_revoked : {
		code : 2504,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2504",
	},
	user_login_failed_user_name : {
		code : 2505,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2505",
	},
	user_login_failed_password : {
		code : 2506,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2506",
	},
	user_login_failed_name_and_password : {
		code : 2507,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2507",
	},
	user_login_failed_user_not_found : {
		code : 2508,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2508",
	},

	user_logout_failed : {
		code : 2530,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2530",
	},

	user_invalid_username : {
		code : 2540,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2540",
	},
	user_invalid_user_input : {
		code : 2541,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:2541",
	},

    // db
	db_unknown : {
		code : 3000,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:3000",
	},
	db_failed_init : {
		code : 3010,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:3010",
	},
	db_failed_migration : {
		code : 3011,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:3011",
	},
	db_skipped_migration : {
		code : 3012,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:3012",
	},
	db_failed_load : {
		code : 3013,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:3013",
	},
	db_failed_query : {
		code : 3014,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:3014",
	},
    
	db_failed_fetch_request : {
		code : 3020,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:3020",
	},
	
    // case db_failed_fetch_by_ids = 3021
    // case db_failed_creating_fetch_request = 3022
    // case db_failed_update_request = 3030
    // case db_failed_save = 3040
    // case db_failed_autosave = 3041
    // case db_failed_delete = 3050

    // UI
	ui_unknown : {
		code : 5000,
		reasonPhrase : "TODO - reason phrase for|stt_phrase|code:5000",
	},

}
