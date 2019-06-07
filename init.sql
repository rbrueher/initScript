

------------------------------------------------------------
-- Create Authentication contribution  schema
------------------------------------------------------------





------------------------------------------------------------
-- Create Admin contribution  schema
------------------------------------------------------------

-- Creates ACE Admin Service tables.

/*
 * A configuration that defines a KeyStoreProvider.
 *
 * Columns:
 *
 * id                   - The unique identifier for this SslClientProvider.
 * name                 - The name of the SslClientProvider.
 * description          - A description for the SslClientProvider.
 * key_store            - The data that is loaded into the KeyStore. The content of this binary data is BASE64 encoded.
 * key_store_type       - The type of the KeyStore. For example 'JCEKS', 'JKS', or 'PKCS12'.
 * password             - A password used to unlock the KeyStore.
 * security_provider    - The name of a KeyStore Security Provider.  For example 'SunJSSE'.  If not set the JVM default will be used.
 * modified_date        - The date-time (UTC) when this SslClientProvider was last modified.
 * encrypted            - Set true if the password is encrypted, false otherwise.
 *
 * Constraints:
 *
 * as_key_store_provider_pkey                  - PRIMARY KEY on id.
 * as_key_store_provider_unique_name_idx       - Case insensitive UNIQUE index on name.
 *
 * Sequence:
 *
 * as_key_store_provider_id_seq    - INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1
 */
CREATE TABLE IF NOT EXISTS as_key_store_provider
(
    id                  SERIAL PRIMARY KEY,
    name                VARCHAR(100) NOT NULL,
    description         VARCHAR(1024) NULL,
    key_store           VARCHAR(10000000) NOT NULL,
    key_store_type      VARCHAR(100) NOT NULL,
    password            VARCHAR(1024) NULL,
    security_provider   VARCHAR(100) NULL,
    modified_date       timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    encrypted           BOOLEAN NOT NULL
);

/*
 * A configuration that defines an SslClientProvider.
 *
 * Columns:
 *
 * id                               - The unique identifier for this SslClientProvider.
 * name                             - The name of the SslClientProvider.
 * description                      - A description for the SslClientProvider.
 * trust_store_provider_name        - The name of the KeyStoreProvider to use as the Trust Store.
 * enable_mutual_authentication     - Set true to enable Mutual Authentication.
 * identity_store_provider_name     - The name of the KeyStoreProvider containing the identity used for Mutual Authentication.  Required if enable_mutual_authentication is true.
 * key_alias_for_identity           - The alias name for the identity used for Mutual Authentication.
 * key_alias_password               - The password for the identity used for Mutual Authentication.
 * security_provider                - The name of an SSL Security Provider.  For example 'SunJSSE'.  If not set the JVM default will be used.
 * ssl_protocol                     - The SSL Protocol used.
 *                                      One of: SSL_V3, TLS_V1, TLS_V1_1, TLS_V1_2
 * ssl_cipher_class                 - The SSL Class used.
 *                                      One of: ALL_CIPHERS, AT_LEAST_128_BITS, AT_LEAST_256_BITS, EXPLICIT_CIPHERS, FIPS_CIPHERS, MORE_THAN_128_BITS, NO_EXPORTABLE_CIPHERS
 * explicit_cipher_list             - A list of explicitly named Ciphers.  This must be set if ssl_cipher_class is set to EXPLICIT_CIPHERS.
 * verify_remote_hostname           - Set true to verify the Host name.  This applies only when Mutual Authentication is enabled
 * expected_remote_hostname         - The expected Host name value to check.  Required if verify_remote_hostname is set true.
 * modified_date                    - The date-time (UTC) when this SslClientProvider was last modified.
 * encrypted                        - Set true if the key_alias_for_identity and key_alias_password are encrypted, false otherwise.
 *
 * Constraints:
 *
 * as_ssl_client_provider_pkey                                  - PRIMARY KEY on id.
 * as_ssl_client_provider_unique_name_idx                       - Case insensitive UNIQUE index on name.
 * as_ssl_client_provider_ssl_protocol_check                    - CHECK on ssl_protocol
 * as_ssl_client_provider_ssl_cipher_class_check                - CHECK on ssl_cipher_class
 * as_ssl_client_provider_trust_store_provider_id_fkey          - FOREIGN KEY on trust_store_provider_id
 * as_ssl_client_provider_identity_store_provider_id_fkey       - FOREIGN KEY on identity_store_provider_id
 * as_ssl_client_provider_enable_mutual_authentication_check    - CHECK: If enable_mutual_authentication is true then identity_store_provider_id and key_alias_for_identity are required.
 * as_ssl_client_provider_ssl_cipher_explicit_check             - CHECK: If ssl_cipher_class is set to 'EXPLICIT_CIPHERS' then explicit_cipher_list is required.
 *
 * Sequence:
 *
 * as_ssl_client_provider_id_seq    - INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1
 */
CREATE TABLE IF NOT EXISTS as_ssl_client_provider
(
    id                              SERIAL PRIMARY KEY,
    name                            VARCHAR(100) NOT NULL,
    description                     VARCHAR(1024) NULL,
    trust_store_provider_id         INTEGER NOT NULL REFERENCES as_key_store_provider(id) ON DELETE RESTRICT,
    enable_mutual_authentication    BOOLEAN DEFAULT false NOT NULL,
    identity_store_provider_id      INTEGER NULL REFERENCES as_key_store_provider(id) ON DELETE RESTRICT,
    key_alias_for_identity          VARCHAR(1024) NULL,
    key_alias_password              VARCHAR(1024) NULL,
    security_provider               VARCHAR(100) NULL,
    ssl_protocol                    VARCHAR(8) DEFAULT 'TLS_V1_2' NOT NULL CHECK(
                                        ssl_protocol = 'SSL_V3'
                                        OR ssl_protocol = 'TLS_V1'
                                        OR ssl_protocol = 'TLS_V1_1'
                                        OR ssl_protocol = 'TLS_V1_2'),
    ssl_cipher_class                VARCHAR(21) DEFAULT 'AT_LEAST_256_BITS' NOT NULL CHECK(
                                        ssl_cipher_class = 'ALL_CIPHERS'
                                        OR ssl_cipher_class = 'AT_LEAST_128_BITS'
                                        OR ssl_cipher_class = 'AT_LEAST_256_BITS'
                                        OR ssl_cipher_class = 'EXPLICIT_CIPHERS'
                                        OR ssl_cipher_class = 'FIPS_CIPHERS'
                                        OR ssl_cipher_class = 'MORE_THAN_128_BITS'
                                        OR ssl_cipher_class = 'NO_EXPORTABLE_CIPHERS'),
    explicit_cipher_list            VARCHAR(8192) NULL,
    verify_remote_hostname          BOOLEAN DEFAULT false NOT NULL,
    expected_remote_hostname        VARCHAR(256) NULL,
    modified_date                   timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    encrypted                       BOOLEAN NOT NULL,
    CONSTRAINT as_ssl_client_provider_enable_mutual_authentication_check CHECK (
        enable_mutual_authentication = false OR
        (identity_store_provider_id IS NOT NULL AND key_alias_for_identity IS NOT NULL)),
    CONSTRAINT as_ssl_client_provider_ssl_cipher_explicit_check CHECK (
        ssl_cipher_class != 'EXPLICIT_CIPHERS' OR explicit_cipher_list IS NOT NULL)
);

/*
 * A configuration that defines an HttpClient.
 *
 * Columns:
 *
 * id                       - The unique identifier for this HttpClient.
 * name                     - The name of the HttpClient.
 * description              - A description for the HttpClient.
 * machine_name             - The name of the host that accepts the incoming requests.
 * port                     - The port number on which to invoke outgoing HTTP requests.
 * socket_timeout           - The timeout in milliseconds waiting for data or a maximum period inactivity between consecutive data packets, default=0.
 * connection_timeout       - The timeout in milliseconds until a connection is established.
 * accept_redirect          - Indicates whether the HTTP method should automatically follow HTTP redirects, default=false.
 * reuse_address            - Controls reuse of a socket address, default=false.
 * suppress_tcp_delay       - Determines whether the Nagle algorithm is used, default: true
 * stale_check_validation   - A time value in milliseconds that determines how a stale connection check is applied, default=-1.
 * time_to_live             - The maximum time in milliseconds that a connection remains available for use, default=-1.
 * buffer_size              - Socket buffer size in bytes, default=-1
 * local_socket_address     - Local host address to be used for creating the socket.
 * configure_proxy          - Set true to configure the HTTP Proxy options, default=false.
 * proxy_type               - Type of proxy server, HTTP or SOCKS V4 / V5.  Required if configure_proxy set true.
 * proxy_host               - Address of the proxy host.  Required if configure_proxy set true.
 * proxy_port               - Port of the proxy host.  Required if configure_proxy set true.
 * conf_basic_auth          - Set true to configure access to proxy server with a username and password, default=false.
 * username                 - The username used for the proxy server BASIC authentication.  Required if conf_basic_auth is set true.
 * password                 - The password used for the proxy server BASIC authentication.  Applies only if conf_basic_auth is set true.
 * enable_ssl               - Set true to enable SSL, default=false.
 * ssl_client_provider_id   - The id that references the as_ssl_client_provider table.  Required if enable_ssl set true.
 * modified_date            - The date-time (UTC) when this HttpClient was last modified.
 * reference_count          - This is used to determine current references to this HttpClient.
 * encrypted                - Set true if the username and password are encrypted, false otherwise.
 *
 * Constraints:
 *
 * as_http_client_pkey                          - PRIMARY KEY on id.
 * as_http_client_unique_name_idx               - Case insensitive UNIQUE index on name.
 * as_http_client_proxy_type_check              - CHECK on proxy_type.
 * as_http_client_ssl_client_provider_id_fkey   - FOREIGN KEY on ssl_client_provider_id
 * as_http_client_configure_proxy_check         - CHECK: If configure_proxy is true then proxy_type, proxy_host, proxy_port are required.
 * as_http_client_conf_basic_auth_check         - CHECK: If conf_basic_auth is true then username is required.
 * as_http_client_enable_ssl_check              - CHECK: If enable_ssl is true then ssl_client_provider_id is required.
 *
 * Sequence:
 *
 * as_http_client_id_seq            - INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1
 */
CREATE TABLE IF NOT EXISTS as_http_client
(
    id                      SERIAL PRIMARY KEY,
    name                    VARCHAR(100) NOT NULL,
    description             VARCHAR(1024) NULL,
    machine_name            VARCHAR(256) NOT NULL,
    port                    INTEGER NOT NULL,
    socket_timeout          INTEGER DEFAULT 0 NOT NULL,
    connection_timeout      INTEGER DEFAULT 0 NOT NULL,
    accept_redirect         BOOLEAN DEFAULT false NOT NULL,
    reuse_address           BOOLEAN DEFAULT false NOT NULL,
    suppress_tcp_delay      BOOLEAN DEFAULT true NOT NULL,
    stale_check_validation  INTEGER DEFAULT -1 NOT NULL,
    time_to_live            INTEGER DEFAULT -1 NOT NULL,
    buffer_size             INTEGER DEFAULT -1 NOT NULL,
    local_socket_address    VARCHAR(256) NULL,
    configure_proxy         BOOLEAN DEFAULT false NOT NULL,
    proxy_type              VARCHAR(11) NULL CHECK(
                                proxy_type = 'HTTP'
                                OR proxy_type = 'SOCKS_V4_V5'
                                OR proxy_type IS NULL),
    proxy_host              VARCHAR(256) NULL,
    proxy_port              INTEGER NULL,
    conf_basic_auth         BOOLEAN DEFAULT false NOT NULL,
    username                VARCHAR(1024) NULL,
    password                VARCHAR(1024) NULL,
    enable_ssl              BOOLEAN DEFAULT false NOT NULL,
    ssl_client_provider_id  INTEGER NULL REFERENCES as_ssl_client_provider(id) ON DELETE RESTRICT,
    modified_date           timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reference_count         INTEGER DEFAULT 0 NOT NULL,
    encrypted               BOOLEAN NOT NULL,
    CONSTRAINT as_http_client_configure_proxy_check CHECK (
        configure_proxy = false OR
        (proxy_type IS NOT NULL AND proxy_host IS NOT NULL AND proxy_port IS NOT NULL)),
    CONSTRAINT as_http_client_conf_basic_auth_check CHECK (
        conf_basic_auth = false OR username IS NOT NULL),
    CONSTRAINT as_http_client_enable_ssl_check CHECK (
        enable_ssl = false OR ssl_client_provider_id IS NOT NULL)
);

CREATE UNIQUE INDEX as_key_store_provider_unique_name_idx on as_key_store_provider (LOWER(name));
CREATE UNIQUE INDEX as_ssl_client_provider_unique_name_idx on as_ssl_client_provider (LOWER(name));
CREATE UNIQUE INDEX as_http_client_unique_name_idx on as_http_client (LOWER(name));






------------------------------------------------------------
-- Create WebResourceProvisioner contribution  schema
------------------------------------------------------------

/*
 * Database create script for Web Resource Provisioner micro service
 */

/*
 * Application table
 * A row is created for each deployed Application
 */

CREATE TABLE wr_app
(
  id           		NUMERIC(28,0) NOT NULL,
  name          	VARCHAR(256) NOT NULL,
  ownerSub			NUMERIC(28,0) NOT NULL,
  ownerSandbox      NUMERIC(28,0) NOT NULL,
  applicationType	VARCHAR(20) NOT NULL,
  publishedVersion  NUMERIC(28,0),
  latestVersion		NUMERIC(28,0),
  owner				NUMERIC(28,0),
  creationDate		TIMESTAMP WITH TIME ZONE NOT NULL,
  lastModifiedDate	TIMESTAMP WITH TIME ZONE NOT NULL,
  lastModifiedBy	NUMERIC(28,0) NOT NULL,
  checksum			VARCHAR(256),
  CONSTRAINT wr_app_pk PRIMARY KEY (id),
  CONSTRAINT wr_app_unique UNIQUE (name, ownerSub, ownerSandbox, applicationType)
);

CREATE SEQUENCE wr_app_seq START WITH 1 INCREMENT BY 1 CACHE 20;

/*
 * Application versions table
 * A row is created for each version of an application
 */
CREATE TABLE wr_app_version
(
  id				NUMERIC(28,0) NOT NULL,
  label				VARCHAR(256),
  ownerApp			NUMERIC(28,0) NOT NULL,
  version			NUMERIC(28,0) NOT NULL,
  name				VARCHAR(256),
  creationDate		TIMESTAMP WITH TIME ZONE NOT NULL,
  lastModifiedDate	TIMESTAMP WITH TIME ZONE NOT NULL,
  lastModifiedBy	NUMERIC(28,0) NOT NULL,
  permissions		NUMERIC(28,0) NOT NULL,
  CONSTRAINT wr_app_version_pk PRIMARY KEY (id),
  CONSTRAINT wr_app_version_unique UNIQUE (version, ownerApp),
  CONSTRAINT wr_app_version_fk1 FOREIGN KEY (ownerApp) REFERENCES wr_app (id)
);

CREATE INDEX wr_app_version_fk1_idx ON wr_app_version (ownerApp);

CREATE SEQUENCE wr_app_version_seq START WITH 1 INCREMENT BY 1 CACHE 20;

ALTER TABLE wr_app ADD CONSTRAINT wr_app_fk1 FOREIGN KEY (publishedVersion) REFERENCES wr_app_version (id);
ALTER TABLE wr_APP ADD CONSTRAINT wr_app_fk2 FOREIGN KEY (latestVersion) REFERENCES wr_app_version (id);
 
CREATE INDEX wr_app_fk1_idx ON wr_app (publishedVersion);

CREATE INDEX wr_app_fk2_idx ON wr_app (latestVersion);
/*
 * Artifacts table
 * A row is created for each unique artifact in the system
 */
CREATE TABLE wr_artifact
(
  id				NUMERIC(28,0) NOT NULL,
  artifactName		VARCHAR(1024) NOT NULL,
  artifactVersion	NUMERIC(28,0) NOT NULL,
  ownerApp			NUMERIC(28,0) NOT NULL,
  author			NUMERIC(28,0) NOT NULL,
  creationDate		TIMESTAMP WITH TIME ZONE NOT NULL,
  lastModifiedDate	TIMESTAMP WITH TIME ZONE NOT NULL,
  lastModifiedBy	NUMERIC(28,0) NOT NULL,
  artifactRef		VARCHAR(1024) NOT NULL,
  artifactCheckSum	VARCHAR(256) NOT NULL,
  CONSTRAINT wr_artifact_pk PRIMARY KEY (id),
  CONSTRAINT wr_artifact_unique UNIQUE (artifactRef),
  CONSTRAINT wr_artifact_fk1 FOREIGN KEY (ownerApp) REFERENCES wr_app (id)
);

CREATE INDEX wr_artifact_fk1_idx ON wr_artifact (ownerApp);
CREATE INDEX wr_artifact_name_idx ON wr_artifact (artifactName);

CREATE SEQUENCE wr_artifact_seq START WITH 1 INCREMENT BY 1 CACHE 20;

/*
 * Artifact versions table
 * Links artifacts to the application versions
 * Each artifact can belong to multiple versions of the application
 */
CREATE TABLE wr_artifact_ver
(
  versionId			NUMERIC(28,0) NOT NULL,
  artifactId		NUMERIC(28,0) NOT NULL,
  CONSTRAINT wr_artifact_ver_pk PRIMARY KEY (versionId, artifactId),
  CONSTRAINT wr_artifact_ver_fk1 FOREIGN KEY (artifactId) REFERENCES wr_artifact (id),
  CONSTRAINT wr_artifact_ver_fk2 FOREIGN KEY (versionId) REFERENCES wr_app_version (id)
);

CREATE INDEX wr_artifact_ver_fk1_idx ON wr_artifact_ver (artifactId);

CREATE INDEX wr_artifact_ver_fk2_idx ON wr_artifact_ver (versionId);

/*
 * Lock table to ensure applications are not updated concurrently
 */
CREATE TABLE wr_app_lock
(
  lockId					VARCHAR(512) NOT NULL,
  CONSTRAINT wr_app_lock_pk PRIMARY KEY (lockId)
);

/* View to allow the artifact_ref for a particular artifact / version to be found
 * by name
 * Used by HTTP servlets to quickly return the required artifact
 */
CREATE VIEW wr_artifact_view (name, artifactRef, versionId, artifactId) AS 
SELECT artifact.artifactName, artifact.artifactRef, artifact_ver.versionId, artifact.id
FROM wr_artifact artifact, wr_artifact_ver artifact_ver
WHERE artifact.id = artifact_ver.artifactId;

ALTER TABLE wr_artifact ADD artifactSize NUMERIC(28,0);
ALTER TABLE wr_artifact ADD mimeType VARCHAR(256);
ALTER TABLE wr_artifact ADD description VARCHAR(1024);

ALTER TABLE wr_app ADD extRef VARCHAR(100);

/*
 * Tag table
 * A row is created for each Tag in the system
 */
CREATE TABLE wr_tag
(
  id           		NUMERIC(28,0) NOT NULL,
  name          	VARCHAR(256) NOT NULL,
  ownerSub			NUMERIC(28,0) NOT NULL,
  CONSTRAINT wr_tag_pk PRIMARY KEY (id),
  CONSTRAINT wr_tag_unique UNIQUE (name, ownerSub)
);

CREATE SEQUENCE wr_tag_seq START WITH 1 INCREMENT BY 1 CACHE 20;

/* 
 * app_tag table 
 * Creates links between applications and tags, each application can have multiple tags
*/
CREATE TABLE wr_app_tag
(
  id				NUMERIC(28,0) NOT NULL,
  tag				NUMERIC(28,0) NOT NULL,
  app				NUMERIC(28,0) NOT NULL,
  CONSTRAINT wr_app_tag_pk PRIMARY KEY (id),
  CONSTRAINT wr_app_tag_unique UNIQUE (tag, app),
  CONSTRAINT wr_app_tag_fk1 FOREIGN KEY (tag) REFERENCES wr_tag (id),
  CONSTRAINT wr_app_tag_fk2 FOREIGN KEY (app) REFERENCES wr_app (id)
);

CREATE SEQUENCE wr_app_tag_seq START WITH 1 INCREMENT BY 1 CACHE 20;

-- Indexes for user id updates
CREATE INDEX CONCURRENTLY wr_app_ids ON wr_app (owner, lastModifiedBy);

CREATE INDEX CONCURRENTLY wr_app_version_ids ON wr_app_version (lastModifiedBy);

CREATE INDEX CONCURRENTLY wr_artifact_ids ON wr_artifact (author, lastModifiedBy);

/* 
 * artifact_data table
 * Storeds binary data for artifact
*/
CREATE TABLE wr_artifact_data
(
  artifactRef		VARCHAR(1024) NOT NULL,
  data				bytea NOT NULL,
  lastModifiedDate	TIMESTAMP WITH TIME ZONE NOT NULL,
  artifactSize 		NUMERIC(28,0),
  mimeType 			VARCHAR(256), 
  CONSTRAINT wr_artifact_data_pk PRIMARY KEY (artifactRef)
);



------------------------------------------------------------
-- Create WorkPresentiation contribution  schema
------------------------------------------------------------

--
-- Script to initialise the Work Presentation Database Schema for postgres DB
--
CREATE SEQUENCE wp_application_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE wp_worktype_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE wp_presentation_channel_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE wp_presentation_artifact_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE wp_application
(
  id                       NUMERIC(28,0) NOT NULL, -- id assigned from a sequence
  applicationName          VARCHAR(256) NOT NULL,  -- Application label
  applicationId            VARCHAR(256) NOT NULL,  -- Application internal name
  deploymentId             NUMERIC(28,0) NOT NULL, -- Unique number for each deployed version, used in undeploy/status calls
  version				   VARCHAR(256) NOT NULL,
  creationDate		       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT wp_application_pk PRIMARY KEY (id)
);
		
CREATE TABLE wp_worktype (
  id                        NUMERIC(28,0) NOT NULL, -- id assigned from a sequence
  applicationId				NUMERIC(28,0) NOT NULL, -- FK to wp_application(id)
  guid         				VARCHAR(256) NOT NULL,  -- unique guid for a work type
  description				VARCHAR(256) NOT NULL,  -- description
  version					VARCHAR(256) NOT NULL,  -- version in the form 
  piled						BOOLEAN NOT NULL,
  ignoreIncomingData		BOOLEAN NOT NULL,
  reofferOnClose			BOOLEAN NOT NULL,
  reofferOnCancel			BOOLEAN NOT NULL,
  inout						BOOLEAN NOT NULL,
  creationDate				TIMESTAMP WITH TIME ZONE NOT NULL,
  lastModifiedDate			TIMESTAMP WITH TIME ZONE NOT NULL,
  
  CONSTRAINT wp_worktype_pk PRIMARY KEY (id),
  CONSTRAINT wp_worktype_fk1 FOREIGN KEY (applicationId)
    REFERENCES wp_application (id) ON DELETE CASCADE
  
);	


CREATE TABLE wp_presentation_channel (
  id  						NUMERIC(28,0) NOT NULL, -- id assigned from a sequence
  appId						NUMERIC(28,0) NOT NULL, -- FK to wp_application(id)
  name                      VARCHAR(256)  NOT NULL, -- 
  description               VARCHAR(256)  NOT NULL, --
  channelId                 VARCHAR(256)  NOT NULL, --
  domainStr                 VARCHAR(256)  NULL,     --
  targeType					VARCHAR(256)  NOT NULL, -- 
  presentationType			VARCHAR(256)  NOT NULL, -- 
  implementationType		VARCHAR(256)  NOT NULL,
  isDefault                	BOOLEAN NOT NULL, ----
  creationDate				TIMESTAMP WITH TIME ZONE NOT NULL,
  lastModifiedDate			TIMESTAMP WITH TIME ZONE NOT NULL,  
  
  CONSTRAINT wp_presentation_channel_pk PRIMARY KEY (id),
  CONSTRAINT wp_presentation_channel_fk1 FOREIGN KEY (appId)
    REFERENCES wp_application (id) ON DELETE CASCADE
);

CREATE TABLE wp_presentation_artifact (

  artifactId 				NUMERIC(28,0) NOT NULL, -- id assigned from a sequence
  channelId					NUMERIC(28,0) NOT NULL, -- FK wp_presentation_channel (id)
  workTypeId				NUMERIC(28,0) NOT NULL, -- FK wp_worktype (id)
  workTypeGuid				VARCHAR(256) NOT NULL,  -- unique id for a work type
  name						VARCHAR(256) NOT NULL,  -- 
  version					VARCHAR(256) NOT NULL,  -- 
  artifactType              VARCHAR(256) NOT NULL,  -- FORM or PAGEFLOW
  creationDate				TIMESTAMP WITH TIME ZONE NOT NULL,
  lastModifiedDate			TIMESTAMP WITH TIME ZONE NOT NULL,
  
  CONSTRAINT wp_presentation_artifact_pk PRIMARY KEY (artifactId),
  CONSTRAINT wp_presentation_artifact_fk1 FOREIGN KEY (channelId)
    REFERENCES wp_presentation_channel (id) ON DELETE CASCADE
  
);

CREATE TABLE wp_form
(
  artifactId 				NUMERIC(28,0) NOT NULL,  -- FK to wp_presentation_artifact (artifactId)
  identifier 				VARCHAR(256) NOT NULL,   -- form identifier, complete path
  relativePath				VARCHAR(256) NOT NULL,   -- form relativePath
  name						VARCHAR(256) NOT NULL,   -- activity name
  version 					VARCHAR(256) NOT NULL,   -- version
  
  CONSTRAINT wp_form_pk PRIMARY KEY (artifactId),
  CONSTRAINT wp_form_fk1 FOREIGN KEY (artifactId)
    REFERENCES wp_presentation_artifact (artifactId) ON DELETE CASCADE
  
);	


CREATE TABLE wp_worktype_model
(
  worktypeId 				NUMERIC(28,0) NOT NULL,  -- FK to wp_worktype (id)
  paramName 				VARCHAR(256) NOT NULL,   -- parameter name
  paramType					VARCHAR(256) NOT NULL,   -- parameter type
  isOptional				BOOLEAN NOT NULL,   	 -- is optional
  isArray 					BOOLEAN NOT NULL,   	 -- is array
  isInout					BOOLEAN NOT NULL,   	 -- is array
  
  CONSTRAINT wp_worktype_model_pk PRIMARY KEY (worktypeId, paramName)  
);	


CREATE TABLE wp_worktype_model_simple
(
  worktypeId 				NUMERIC(28,0) NOT NULL,  -- FK to wp_worktype (id)
  paramName 				VARCHAR(256)  NOT NULL,  -- parameter name
  length					NUMERIC(10,0) NULL,      -- parameter length
  decimal					NUMERIC(10,0) NULL,   	 -- no of decimals
	  
  CONSTRAINT wp_worktype_model_simple_pk PRIMARY KEY (worktypeId, paramName)

);	


CREATE TABLE wp_worktype_model_complex
(
  worktypeId 				NUMERIC(28,0) NOT NULL,  -- FK to wp_worktype (id)
  paramName 				VARCHAR(256) NOT NULL,   -- parameter name
  class						VARCHAR(256) NOT NULL,   -- class name
  
  CONSTRAINT wp_worktype_model_complex_pk PRIMARY KEY (worktypeId, paramName)
);	



------------------------------------------------------------
-- Create CaseDataManager contribution  schema
------------------------------------------------------------

CREATE SEQUENCE cdm_applications_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE cdm_datamodels_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE cdm_types_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE cdm_states_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE cdm_links_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE cdm_cases_int_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE cdm_applications
(
  id                        NUMERIC(28,0) NOT NULL, -- id assigned from a sequence (primary key for this table)
  application_name          VARCHAR(256) NOT NULL, 
  application_id            VARCHAR(256) NOT NULL,  -- Fully qualified application name (com.example.ProjectX)
  deployment_id             NUMERIC(28,0) NOT NULL, -- Unique number for each deployed version, used in undeploy/status calls
  major_version             INTEGER NOT NULL, -- Columns types for the 4 version number parts mirror those used by DEM's schema
  minor_version             INTEGER NOT NULL,
  micro_version             INTEGER NOT NULL,
  qualifier                 VARCHAR(36)	NOT NULL,
  deployment_timestamp      TIMESTAMP NOT NULL,
  CONSTRAINT cdm_applications_pk PRIMARY KEY (id)
);

CREATE TABLE cdm_datamodels
(
  id                        NUMERIC(28,0) NOT NULL, -- id assigned from a sequence (primary key for this table)
  application_id			NUMERIC(28,0) NOT NULL, -- id of application (numeric, assigned from sequence) in cdm_applications
  major_version             NUMERIC(10,0) NOT NULL, -- e.g. 1 (duplicated from cdm_applications to allow cdm_datamodels_unq) 
  namespace                 VARCHAR(256) NOT NULL, -- e.g. "com.example.carmodel"
  model                     TEXT NOT NULL,
  script                    TEXT, -- TODO make this NOT NULL once everything is integrated
  CONSTRAINT cdm_datamodels_pk PRIMARY KEY (id),
  CONSTRAINT cdm_datamodels_fk1 FOREIGN KEY (application_id)
    REFERENCES cdm_applications (id) ON DELETE CASCADE,
  CONSTRAINT cdm_datamodels_unq UNIQUE (namespace, major_version)    
);

CREATE TABLE cdm_types
(
	id                     NUMERIC(28,0) NOT NULL, -- id assigned from a sequence (primary key for this table)
	datamodel_id           NUMERIC(28,0) NOT NULL, -- id of datamodel in cdm_datamodels
	name                   VARCHAR(256) NOT NULL, -- name of type (e.g. 'Address')
	is_case                BOOLEAN NOT NULL, -- true if case, false if not
  CONSTRAINT cdm_types_pk PRIMARY KEY (id),
  CONSTRAINT cdm_types_fk1 FOREIGN KEY (datamodel_id)
    REFERENCES cdm_datamodels (id) ON DELETE CASCADE
);

CREATE TABLE cdm_states -- TODO Does order of states need to be maintained? If so, need an idx column.
(
    id                     NUMERIC(28,0) NOT NULL, -- id assigned from a sequence (primary key for this table)
    type_id                NUMERIC(28,0) NOT NULL, -- id of type in cdm_types
    value                  VARCHAR(100) NOT NULL,
    label                  VARCHAR(100) NOT NULL, -- TODO don't think label length is validated
    is_terminal            BOOLEAN NOT NULL,
  CONSTRAINT cdm_states_pk PRIMARY KEY (id),
  CONSTRAINT cdm_states_fk1 FOREIGN KEY (type_id)
    REFERENCES cdm_types (id) ON DELETE CASCADE
);

CREATE TABLE cdm_type_indexes
(
    type_id                NUMERIC(28,0) NOT NULL, -- id of type in cdm_types
	name                   VARCHAR(63) NOT NULL, -- name of index (e.g. 'i_cdm_ordermodel_Address_postcode')
	attribute_name         VARCHAR(256) NOT NULL, -- name of attribute (e.g. 'postcode')
  CONSTRAINT cdm_type_indexes_fk1 FOREIGN KEY (type_id)
    REFERENCES cdm_types (id) -- no 'on delete cascade', as we want to make sure we explicitly remove indexes
);

CREATE TABLE cdm_datamodel_deps
(
  datamodel_id_from			NUMERIC(28,0) NOT NULL, -- id of datamodel in cdm_datamodels
  datamodel_id_to			NUMERIC(28,0) NOT NULL, -- id of datamodel on which the first depends
  CONSTRAINT cdm_datamodel_deps_pk PRIMARY KEY (datamodel_id_from, datamodel_id_to),
  CONSTRAINT cdm_datamodel_deps_fk1 FOREIGN KEY (datamodel_id_from) 
    REFERENCES cdm_datamodels (id) ON DELETE CASCADE,
  CONSTRAINT cdm_datamodel_deps_fk2 FOREIGN KEY (datamodel_id_to) 
    REFERENCES cdm_datamodels (id) -- no 'on delete cascade' (no desire to allow the 'to' model to be deleted while the 'from' depends on it)
);

CREATE TABLE cdm_identifier_infos
(
  type_id                   NUMERIC(28,0) NOT NULL, -- id of type in cdm_types
  prefix                    VARCHAR(32), 
  suffix                    VARCHAR(32), 
  min_num_length            NUMERIC(2,0),
  next_num                  NUMERIC(15,0) NOT NULL,
  CONSTRAINT cdm_identifier_infos_pk PRIMARY KEY (type_id),
  CONSTRAINT cdm_identifier_infos_fk_type_id FOREIGN KEY (type_id)
    REFERENCES cdm_types (id) ON DELETE CASCADE
);

CREATE TABLE cdm_links
(
  id                        NUMERIC(28,0) NOT NULL, -- id assigned from a sequence (primary key for this table)
  end1_type_id              NUMERIC(28,0) NOT NULL, -- id of type in cdm_types
  end1_name                 VARCHAR(256) NOT NULL,  -- name of end
  end1_is_array             BOOLEAN NOT NULL,       -- true if array
  end2_type_id              NUMERIC(28,0) NOT NULL, 
  end2_name                 VARCHAR(256) NOT NULL,
  end2_is_array             BOOLEAN NOT NULL,
  CONSTRAINT cdm_links_pk PRIMARY KEY (id),
  CONSTRAINT cdm_links_unq UNIQUE (end1_type_id, end1_name, end2_type_id, end2_name), 
  CONSTRAINT cdm_links_fk_end1_type_id FOREIGN KEY (end1_type_id)
    REFERENCES cdm_types (id) ON DELETE CASCADE,
  CONSTRAINT cdm_links_fk_end2_type_id FOREIGN KEY (end2_type_id)
    REFERENCES cdm_types (id) ON DELETE CASCADE
);

CREATE TABLE cdm_cases_int
(
  id                        NUMERIC(28,0) NOT NULL, -- (like 'bds_id' in BDS)
  version                   NUMERIC(15,0) NOT NULL, -- (like 'bds_version' in BDS)
  type_id                   NUMERIC(28,0) NOT NULL, -- id of type in cdm_types
  casedata                  JSONB NOT NULL,
  cid                       VARCHAR(400) NOT NULL, 
  state_id                  NUMERIC(28,0) NOT NULL, -- id of state in cdm_states
  created_by                VARCHAR(36) NOT NULL, -- 36 char GUID according to Phill
  creation_timestamp        TIMESTAMP NOT NULL,
  modified_by               VARCHAR(36) NOT NULL, -- 36 char GUID according to Phill
  modification_timestamp    TIMESTAMP NOT NULL,
  CONSTRAINT cdm_cases_int_pk PRIMARY KEY (id),
  CONSTRAINT cdm_cases_int_unq UNIQUE (type_id, cid), -- enforce uniqueness of CID for a given type
  CONSTRAINT cdm_cases_int_fk_type_id FOREIGN KEY (type_id)
	REFERENCES cdm_types (id),
  CONSTRAINT cdm_cases_int_fk_state_id FOREIGN KEY (state_id)
    REFERENCES cdm_states (id) 
);

CREATE TABLE cdm_case_links
(
  link_id                   NUMERIC(28,0) NOT NULL, -- Foreign key to link definition in cdm_links table
  end1_id                   NUMERIC(28,0) NOT NULL, -- id of first case object
  end2_id                   NUMERIC(28,0) NOT NULL, -- id of second case object
  CONSTRAINT cdm_case_links_pk PRIMARY KEY (link_id, end1_id, end2_id),
  CONSTRAINT cdm_case_links_fk_link_id FOREIGN KEY (link_id)
    REFERENCES cdm_links (id) ON DELETE CASCADE,
  CONSTRAINT cdm_case_links_fk_end1_id FOREIGN KEY (end1_id)
    REFERENCES cdm_cases_int (id) ON DELETE CASCADE, -- TODO remove cascade once delete (multiple) cases made to remove links
  CONSTRAINT cdm_case_links_fk_end2_id FOREIGN KEY (end2_id)
    REFERENCES cdm_cases_int (id) ON DELETE CASCADE  -- TODO remove cascade once delete (multiple) cases made to remove links
);

CREATE INDEX idx_casedata ON cdm_cases_int USING gin(casedata);




------------------------------------------------------------
-- Create Kubernetes contribution  schema
------------------------------------------------------------





------------------------------------------------------------
-- Create Runtime contribution  schema
------------------------------------------------------------



------------------------------------------------------------
-- Create ContainerEngine component schema
------------------------------------------------------------

--
-- DAA/RASC Applications
-- 
CREATE TABLE ce_application
(
	application_id		numeric(28) 			NOT NULL,
	application_version	varchar(100)			NOT NULL,
	CONSTRAINT pk_ce_application PRIMARY KEY (application_id)
);

--
-- Modules and process definitions
--
CREATE TABLE ce_def_module
(	
	module_id 				numeric(28)			NOT NULL,
	application_id			numeric(28)     	NOT NULL,
	module_name 			varchar(100)		NOT NULL,
	module_int_name	 		varchar(100)		NOT NULL,
	module_version 			varchar(100)		NOT NULL,
	major_version			integer				NOT NULL,
	minor_version			integer				NOT NULL,
	micro_version			integer				NOT NULL,
	qualifier				varchar(36)			NOT NULL,
	pm_id					numeric(28)			NOT NULL,
	startable				boolean				DEFAULT true,
	CONSTRAINT pk_ce_def_module PRIMARY KEY (module_id)
);

ALTER TABLE ce_def_module ADD CONSTRAINT fk_ce_def_module FOREIGN KEY(application_id) REFERENCES ce_application (application_id) ON DELETE CASCADE;

-- 
-- Create indexes on the table
--
CREATE INDEX ix_filter_cdm_mn ON ce_def_module (module_name);
CREATE INDEX ix_update_cdm_int ON ce_def_module (module_int_name, module_version);

CREATE TABLE ce_def_process
(	
	module_id			numeric(28)			NOT NULL,
	process_id			numeric(28)			NOT NULL,
	process_name		varchar(100)		NOT NULL,
	external_name		varchar(100)		NULL,
	process_def			text				NOT NULL,
	pm_id				numeric(28)			NOT NULL,
	module_version		varchar(100)		NOT NULL,
	CONSTRAINT pk_ce_def_process PRIMARY KEY (module_id, process_id)
);

ALTER TABLE ce_def_process ADD CONSTRAINT fk_ce_def_process FOREIGN KEY(module_id) REFERENCES ce_def_module (module_id) ON DELETE CASCADE;
ALTER TABLE ce_def_process ADD CONSTRAINT uk_ce_def_process UNIQUE (process_id);

-- 
-- Create indexes based on the columns that can be filtered on
--
CREATE INDEX ix_filter_cdp_pn ON ce_def_process (process_name);
CREATE INDEX ix_filter_cdp_mv ON ce_def_process (module_version);

--
-- Process Instances
--
CREATE TABLE ce_inst_process
(
	id						numeric(28)					NOT NULL,
	owner_id				numeric(28)					NOT NULL,
	name					varchar(128)				NOT NULL,
	object_space_id			smallint					NOT NULL,
	object_type_id			integer						NOT NULL,
	details					integer						NULL,
	state					smallint					NOT NULL,
	start_date				timestamp with time zone	NULL,
	completion_date			timestamp with time zone	NULL,
	module_id				numeric(28)					NOT NULL,
    module_name 			varchar(100)		        NOT NULL,
	module_version 			varchar(100)				NOT NULL,
	priority				smallint					NOT NULL,
	priority_override		smallint					NULL,
	creation_date			timestamp with time zone	NOT NULL,
	status					smallint					NOT NULL,
	definition_id			numeric(28)					NOT NULL,
	parent_id				numeric(28)					NULL,
	spawner_task_uri		varchar(64)					NULL,
	instance_state			bytea						NOT NULL,
	failed_instance_summary	text						NULL,
	
	CONSTRAINT pk_ce_inst_process PRIMARY KEY (id)

);

ALTER TABLE ce_inst_process ADD CONSTRAINT fk_ce_inst_process FOREIGN KEY(definition_id) REFERENCES ce_def_process(process_id);

-- 
-- Create indexes based on the columns that can be filtered on
--
CREATE INDEX ix_filter_cip_mn ON ce_inst_process (module_name);
CREATE INDEX ix_filter_cip_pn ON ce_inst_process (name);
CREATE INDEX ix_filter_cip_mv ON ce_inst_process (module_version);
CREATE INDEX ix_filter_cip_st ON ce_inst_process (state);

-- 
-- Process Instance Timers.  Holds both repeating and non-repeating timers
--
CREATE TABLE ce_inst_process_timer
(
    id					numeric(28)					NOT NULL,
    timer_id            varchar(128)                NOT NULL,
    repeating           boolean                     NOT NULL,
    due_date            timestamp with time zone    NULL,
    start_date          timestamp with time zone    NULL,
    end_date            timestamp with time zone    NULL,
    repeat_count        integer                     NULL,
    repeat_interval     integer                     NULL,
    action_spec			bytea						NULL,
    timer_msg           bytea                       NOT NULL,
    
    CONSTRAINT pk_ce_inst_process_timer PRIMARY KEY (id, timer_id)
);

ALTER TABLE ce_inst_process_timer ADD CONSTRAINT fk_ce_inst_process_timer FOREIGN KEY(id) REFERENCES ce_inst_process (id) ON DELETE CASCADE;

--
-- Global signal applications, definitions, waiting receivers and pending messages.
--
CREATE TABLE ce_gs_app
(
	app_id				numeric(28)					NOT NULL,
	name				varchar(128)                NOT NULL,
	version				varchar(32)	                NOT NULL,
	component_version	varchar(32)                 NOT NULL,
	
	CONSTRAINT pk_ce_gs_app PRIMARY KEY (app_id)
);

CREATE TABLE ce_gs_def
(
	app_id				numeric(28)					NOT NULL,
	def_id				numeric(28)					NOT NULL,
	name				varchar(128)                NOT NULL,
	component_version	varchar(32)                 NOT NULL,
	timeout				integer						NOT NULL,
	definition			bytea						NOT NULL,
	
	CONSTRAINT pk_ce_gs_def PRIMARY KEY (def_id)
);
ALTER TABLE ce_gs_def ADD CONSTRAINT fk_ce_gs_def FOREIGN KEY(app_id) REFERENCES ce_gs_app (app_id) ON DELETE CASCADE;

CREATE TABLE ce_gs_receivers
(
	def_id				numeric(28)					NOT NULL,
	id					numeric(28)					NOT NULL,
	instance_id			numeric(28)					NOT NULL,
	task_id				numeric(28)					NOT NULL,
	activity_id			varchar(64)					NOT NULL,
	definition_id		numeric(28)					NOT NULL,
	correlation_id		numeric(28)					NOT NULL,
	correlation_data	varchar(1024)				NULL,
	correlation_blob	bytea						NULL, -- holds correlation data if too large for string column
	
	CONSTRAINT pk_ce_gs_receivers PRIMARY KEY (id)
);
ALTER TABLE ce_gs_receivers ADD CONSTRAINT fk_ce_gs_receivers FOREIGN KEY(def_id) REFERENCES ce_gs_def (def_id) ON DELETE CASCADE;

CREATE TABLE ce_gs_pending
(
	def_id				numeric(28)					NOT NULL,
	id					numeric(28)					NOT NULL,
	creation_date		timestamp with time zone	NOT NULL,
	expiration_date		timestamp with time zone	NULL,
	correlation_id		numeric(28)					NOT NULL,
	correlation_data	varchar(1024)				NULL,
	correlation_blob	bytea						NULL, -- holds correlation data if too large for string column
	signal				bytea						NULL,
	
	CONSTRAINT pk_ce_gs_pending PRIMARY KEY (id)
);
ALTER TABLE ce_gs_pending ADD CONSTRAINT fk_ce_gs_pending FOREIGN KEY(def_id) REFERENCES ce_gs_def (def_id) ON DELETE CASCADE;

--
-- Queue(s)
--
CREATE SEQUENCE ce_request_q_1_seq NO MAXVALUE CYCLE;
CREATE TABLE ce_request_q_1
(
	message_id				numeric(28)					DEFAULT nextval('ce_request_q_1_seq'),
	correlation_id			varchar(128)				NULL,
	priority				integer						NOT NULL,
	delay					timestamp with time zone	NOT NULL,
	payload					bytea						NOT NULL,
	enq_time				timestamp with time zone	NOT NULL,
	retry_count				integer						DEFAULT -1,
	CONSTRAINT pk_ce_request_q_1 PRIMARY KEY (message_id)
);

CREATE INDEX ix_cerq1_correlationid ON ce_request_q_1 (correlation_id);
CREATE INDEX ix_cerq1_delay ON ce_request_q_1 (delay);
CREATE INDEX ix_cerq1_priority_enqtime ON ce_request_q_1 (priority, enq_time);

CREATE SEQUENCE ce_request_q_2_seq NO MAXVALUE CYCLE;
CREATE TABLE ce_request_q_2
(
	message_id				numeric(28)					DEFAULT nextval('ce_request_q_2_seq'),
	correlation_id			varchar(128)				NULL,
	priority				integer						NOT NULL,
	delay					timestamp with time zone	NOT NULL,
	payload					bytea						NOT NULL,
	enq_time				timestamp with time zone	NOT NULL,
	retry_count				integer						DEFAULT -1,
	CONSTRAINT pk_ce_request_q_2 PRIMARY KEY (message_id)
);

CREATE INDEX ix_cerq2_correlationid ON ce_request_q_2 (correlation_id);
CREATE INDEX ix_cerq2_delay ON ce_request_q_2 (delay);
CREATE INDEX ix_cerq2_priority_enqtime ON ce_request_q_2 (priority, enq_time);

--
-- Create the function needed for queue notifications
--
CREATE OR REPLACE FUNCTION notify_listeners()
  RETURNS trigger AS
$BODY$
    BEGIN
        PERFORM pg_notify(TG_TABLE_NAME, 'Queue Notification');
        RETURN NULL;
    END; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
--
-- Create the trigger so that queue notifications will fire on both inserts and updates
--
CREATE TRIGGER ce_request_q_1_notify
  AFTER INSERT OR UPDATE
  ON ce_request_q_1
  FOR EACH ROW
  EXECUTE PROCEDURE notify_listeners();

CREATE TRIGGER ce_request_q_2_notify
  AFTER INSERT OR UPDATE
  ON ce_request_q_2
  FOR EACH ROW
  EXECUTE PROCEDURE notify_listeners();
  
--
-- Sequences
--
CREATE TABLE ce_sequences
(
	sequence_id	integer		NOT NULL,
	description	varchar(50)	NOT NULL,
	value		bigint		NOT NULL,
	CONSTRAINT pk_ce_sequences PRIMARY KEY (sequence_id)
);

INSERT INTO ce_sequences VALUES (1, 'Resource', 1);
INSERT INTO ce_sequences VALUES (2, 'module', 1);
INSERT INTO ce_sequences VALUES (3, 'Schema', 1);
INSERT INTO ce_sequences VALUES (4, 'DefProcess', 1);
INSERT INTO ce_sequences VALUES (5, 'Module', 1);
INSERT INTO ce_sequences VALUES (7, 'WorkItem', 1);
INSERT INTO ce_sequences VALUES (8, 'ProcessInstance', 1);
INSERT INTO ce_sequences VALUES (9, 'GloblaSignalApplication', 1);
INSERT INTO ce_sequences VALUES (10, 'GloblaSignalDefinition', 1);
INSERT INTO ce_sequences VALUES (11, 'GloblaSignalWaitingReceiver', 1);
INSERT INTO ce_sequences VALUES (12, 'GloblaSignalPending', 1);

--
-- Outstanding work items
--
CREATE TABLE ce_inst_outstanding_work
(
	id				numeric(28)						NOT NULL,
	proc_inst_id	varchar(64)						NOT NULL,
	activity_name	varchar(100)					NOT NULL,
	process_name	varchar(100)					NOT NULL,
	work_item_id	numeric(28)						NOT NULL,
	internal_id		varchar(64)						NOT NULL,
	scheduled_date	timestamp with time zone		NOT NULL,
	CONSTRAINT pk_ce_inst_ow PRIMARY KEY (id, work_item_id)
);

ALTER TABLE ce_inst_outstanding_work ADD CONSTRAINT fk_ce_inst_ow FOREIGN KEY(id) REFERENCES ce_inst_process (id) ON DELETE CASCADE;

CREATE INDEX ix_ce_inst_ow_uri ON ce_inst_outstanding_work (internal_id);

--
-- Failed messages
--
CREATE SEQUENCE ce_inst_msg_failed_seq
  MINVALUE 1
  START WITH 1
  INCREMENT BY 1;
  
CREATE TABLE ce_inst_msg_failed
(
	id					numeric(28)					NOT NULL,
	inst_id				numeric(28)					NOT NULL,
	msg_failed			timestamp with time zone	NOT NULL,
	reason_code 		integer						NOT NULL,
	reason_desc			varchar(256)				NULL,
	msg_type			varchar(64)					NOT NULL,
	msg_priority		integer						NOT NULL,
	module_id		    numeric(28)					NOT NULL,
	module_version	    varchar(100)				NULL,
	process_id			numeric(28)					NULL,
	json_data			text						NULL,
	msg					bytea						NULL,
	exception_msg		varchar(512)				NULL,
	exception_stack		text						NULL,
	CONSTRAINT pk_ce_inst_msg_failed PRIMARY KEY (id, module_id, inst_id)
);

ALTER TABLE ce_inst_msg_failed ADD CONSTRAINT fk_ce_inst_msg_failed FOREIGN KEY(module_id) REFERENCES ce_def_module (module_id) ON DELETE CASCADE;

--
-- Table to hold messages for suspended instances
--
CREATE SEQUENCE ce_inst_msg_suspended_seq
  MINVALUE 1
  START WITH 1
  INCREMENT BY 1;
  
CREATE TABLE ce_inst_msg_suspended
(
	id					numeric(28)					NOT NULL,
	inst_id				numeric(28)					NOT NULL,
	msg_suspended		timestamp with time zone	NOT NULL,
	msg_type			varchar(64)					NOT NULL,
	msg_delay			integer						NULL,
	msg					bytea						NOT NULL,
	CONSTRAINT pk_ce_inst_msg_suspended PRIMARY KEY (id, inst_id)
);

ALTER TABLE ce_inst_msg_suspended ADD CONSTRAINT fk_ce_inst_msg_suspended FOREIGN KEY(inst_id) REFERENCES ce_inst_process (id) ON DELETE CASCADE;

-- 
-- Create FK indexes
--
CREATE INDEX ix_fk_ce_def_module ON ce_def_module (application_id);
CREATE INDEX ix_fk_ce_def_process ON ce_def_process (module_id);
CREATE INDEX ix_fk_ce_inst_process ON ce_inst_process (definition_id);
CREATE INDEX ix_fk_ce_inst_msg_failed ON ce_inst_msg_failed (module_id);
CREATE INDEX ix_fk_ce_inst_msg_suspended ON ce_inst_msg_suspended (inst_id);
CREATE INDEX ix_fk_ce_gs_def ON ce_gs_def(app_id);
CREATE INDEX ix_fk_ce_gs_receivers ON ce_gs_receivers(def_id);
CREATE INDEX ix_fk_ce_gs_pending ON ce_gs_pending(def_id);

--
-- Global signal indexes
--
CREATE INDEX ix_ce_gs_receivers_1 ON ce_gs_receivers(def_id, correlation_id);
CREATE INDEX ix_ce_gs_receivers_2 ON ce_gs_receivers(instance_id, task_id);
CREATE INDEX ix_ce_gs_app ON ce_gs_app(name, version);
CREATE INDEX ix_ce_gs_pending ON ce_gs_pending(def_id, correlation_id);




------------------------------------------------------------
-- Create Deployment component schema
------------------------------------------------------------

CREATE TABLE dem_sequences
(
  sequence_id		bigint 		NOT NULL,
  description		varchar(50) NOT NULL,
  value				bigint 		NOT NULL,
  CONSTRAINT dem_sequences_pk PRIMARY KEY (sequence_id)
);
INSERT INTO dem_sequences (sequence_id, description, value) VALUES (1, 'deployment', 1);

CREATE TABLE dem_deployment
(
	id	        		bigint						NOT NULL,
	app_id			  	varchar(256)				NOT NULL,
	app_name           	varchar(256)				NOT NULL,
	major_vers			integer						NOT NULL,
	minor_vers			integer						NOT NULL,
	micro_vers			integer						NOT NULL,
	qualifier			varchar(36)					NOT NULL,
	deploy_date			timestamp with time zone	NOT NULL,
	creation_date  		timestamp with time zone	NULL,
	status				varchar(16)					NOT NULL,
	undeploy_date		timestamp with time zone	NULL,
	CONSTRAINT pk_id PRIMARY KEY(id),
	CONSTRAINT uq_dep_app_id_version UNIQUE (app_id, major_vers, minor_vers, micro_vers, qualifier)
);
CREATE INDEX ix_dem_deployment_status_undeploy_date ON dem_deployment (status, undeploy_date);

CREATE TABLE dem_artefact
(
	artefact_id			integer			NOT NULL,
	deployment_id		bigint			NOT NULL,
	full_path			varchar(440)	NOT NULL,
	name           		varchar(256)	NOT NULL,
	app_id		  		varchar(256)		NULL,
	artefact_name		varchar(256) 		NULL,
	payload				bytea 			NOT NULL,
	CONSTRAINT pk_artefact_id PRIMARY KEY(artefact_id, deployment_id),
	CONSTRAINT fk_dem_artefact FOREIGN KEY(deployment_id) REFERENCES dem_deployment(id) ON DELETE CASCADE,
	CONSTRAINT uq_art_full_path_deployment_id UNIQUE(full_path, deployment_id)
);
CREATE INDEX ix_fk_dem_artefact ON dem_artefact (deployment_id);

CREATE TABLE dem_target
(
	artefact_id		integer			NOT NULL,
	deployment_id	bigint			NOT NULL,
	target_name		varchar(256) 	NOT NULL,
	CONSTRAINT fk_dem_target FOREIGN KEY(artefact_id, deployment_id) REFERENCES dem_artefact(artefact_id, deployment_id) ON DELETE CASCADE
);
CREATE INDEX ix_fk_dem_target ON dem_target (artefact_id, deployment_id);

CREATE TABLE dem_deployment_dependency
(
	id					bigint			NOT NULL,
	app_id			  	varchar(256)	NULL,
	major_vers			integer			NOT NULL,
	minor_vers			integer			NOT NULL,
	micro_vers			integer			NOT NULL,
	qualifier			varchar(36)		NULL,

	provided_by			bigint			NOT NULL,

	CONSTRAINT fk_dem_deployment_dependency_needs FOREIGN KEY(id) REFERENCES dem_deployment(id) ON DELETE CASCADE,
	CONSTRAINT fk_dem_deployment_dependency_provided_by FOREIGN KEY(provided_by) REFERENCES dem_deployment(id),
	
	CONSTRAINT uq_dep_id_app_id UNIQUE (id, app_id)
);
CREATE INDEX ix_dem_dep_dependency_version ON dem_deployment_dependency (major_vers, minor_vers, micro_vers);
CREATE INDEX ix_fk_dem_deployment_dependency_needs ON dem_deployment_dependency(id);
CREATE INDEX ix_fk_dem_deployment_dependency_provided_by ON dem_deployment_dependency(provided_by);




------------------------------------------------------------
-- Create EventCollector component schema
------------------------------------------------------------

--
-- This file contains the create database schema for EC
--

CREATE SEQUENCE ec_event_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE ec_event
(
	event_id				numeric(28)		DEFAULT nextval('ec_event_seq'),
	message_category		varchar(32)		NOT NULL,
	message_id				varchar(256)	NOT NULL,
	message					varchar(256)	NULL,
	severity				varchar(32)		NULL,
	event_timestamp			timestamp without time zone	NULL,
	managed_obj_id			varchar(256)	NULL,
	principal_id			varchar(256)	NULL,
	principal_name			varchar(256)	NULL,
	managed_obj_name		varchar(256)	NULL,
	managed_obj_version		varchar(64)		NULL,
	managed_obj_type		varchar(256)	NULL,
	managed_obj_status		varchar(256)	NULL,
	managed_obj_url			varchar(256)	NULL,
	managed_obj_details		text			NULL,
	parent_obj_id			varchar(256)	NULL,
	app_name				varchar(256)	NULL,
	wi_schedule_start		timestamp without time zone	NULL,
	wi_schedule_end			timestamp without time zone	NULL,
	wi_org_ent_list			text			NULL,
	wi_priority				bigint			NULL,
	ext_message				varchar(2000)	NULL,
	retry_time				varchar(128)	NULL,
	resource_id				varchar(64)		NULL,
	resource_name			varchar(256)	NULL,
	entity_id				varchar(256)	NULL,
	entity_type				varchar(64)		NULL,
	channel_id				varchar(256)	NULL,
	app_act_name			varchar(256)	NULL,
	app_act_model_id		varchar(256)	NULL,
	app_act_instance_id		varchar(256)	NULL,
	sys_action_comp_id		varchar(256)	NULL,
	sys_action_id			varchar(256)	NULL,
	parent_proc_ins_id		varchar(256)	NULL,
	parent_act_ins_id		varchar(256)	NULL,
	sub_proc_ins_id			varchar(256)	NULL,
	sub_proc_name			varchar(256)	NULL,
	process_priority		varchar(64)		NULL,
	module_name				varchar(256)	NULL,
	prior_step_id			varchar(256)	NULL,
	sub_proc_ver			varchar(64)		NULL,
	model_major_version		varchar(32)		NULL,
	model_version			varchar(32)		NULL,
	role_name				varchar(256)	NULL,
	iteration				bigint			NULL,
	iteration_id			varchar(64)		NULL,
	host_task_name			varchar(256)	NULL,
	host_task_type			varchar(256)	NULL,
	interrupts_main_flow	varchar(256)	NULL,
	attribute1				bigint			NULL,
	attribute2				varchar(64)		NULL,
	attribute3				varchar(64)		NULL,
	attribute4				varchar(64)		NULL,
	attribute5				decimal(38, 10)	NULL,
	attribute6				timestamp		NULL,
	attribute7				timestamp		NULL,
	attribute8				varchar(20)		NULL,
	attribute9				varchar(20)		NULL,
	attribute10				varchar(20)		NULL,
	attribute11				varchar(20)		NULL,
	attribute12				varchar(20)		NULL,
	attribute13				varchar(20)		NULL,
	attribute14				varchar(20)		NULL,
	attribute15				bigint			NULL,
	attribute16				decimal(38, 10)	NULL,
	attribute17				decimal(38, 10)	NULL,
	attribute18				decimal(38, 10)	NULL,
	attribute19				timestamp		NULL,
	attribute20				timestamp		NULL,
	attribute21				varchar(20)		NULL,
	attribute22				varchar(20)		NULL,
	attribute23				varchar(20)		NULL,
	attribute24				varchar(20)		NULL,
	attribute25				varchar(20)		NULL,
	attribute26				varchar(20)		NULL,
	attribute27				varchar(64)		NULL,
	attribute28				varchar(64)		NULL,
	attribute29				varchar(64)		NULL,
	attribute30				varchar(64)		NULL,
	attribute31				varchar(64)		NULL,
	attribute32				varchar(64)		NULL,
	attribute33				varchar(64)		NULL,
	attribute34				varchar(64)		NULL,
	attribute35				varchar(64)		NULL,
	attribute36				varchar(64)		NULL,
	attribute37				varchar(64)		NULL,
	attribute38				varchar(64)		NULL,
	attribute39				varchar(256)	NULL,
	attribute40				varchar(256)	NULL,
	CONSTRAINT pk_ec_event PRIMARY KEY (event_id)
)
WITH (OIDS=FALSE);

-- When we make a request for a given set of events for an entity we do the select
-- on the message category and the managed object Id. This composite index will supply
-- the best index as we will alway use the message_category when we do a search
-- for the managed object id
CREATE INDEX ec_event_idx1 ON ec_event (message_category, managed_obj_id);

-- Add the required index to support sorting and filtering
-- Strings require case insensitive searching, this is done in the index
CREATE INDEX ec_event_idx2 ON ec_event (event_timestamp);
CREATE INDEX ec_event_idx3 ON ec_event (message_id);
CREATE INDEX ec_event_idx4 ON ec_event (severity);
CREATE INDEX ec_event_idx5 ON ec_event (event_timestamp);
CREATE INDEX ec_event_idx6 ON ec_event (principal_name);

CREATE TABLE ec_event_attr
(
	event_id			numeric(28)		NOT NULL,
	attribute_name		varchar(256)	NOT NULL,
	attribute_value		text			NOT NULL,
	CONSTRAINT pk_ec_event_attr PRIMARY KEY (event_id, attribute_name)
)
WITH (OIDS=FALSE);

ALTER TABLE ec_event_attr ADD CONSTRAINT fk_ec_event_attr FOREIGN KEY(event_id) REFERENCES ec_event (event_id) ON DELETE CASCADE;

-- Additional Attributes require an index of the foreign key
CREATE INDEX ec_event_attr_idx1 ON ec_event_attr (event_id);


CREATE TABLE ec_event_case_ref
(
	event_id			numeric(28)		NOT NULL,
	case_reference		varchar(256)	NOT NULL,
	CONSTRAINT pk_ec_event_case_ref PRIMARY KEY (event_id, case_reference)
)
WITH (OIDS=FALSE);

ALTER TABLE ec_event_case_ref ADD CONSTRAINT fk_ec_event_case_ref FOREIGN KEY(event_id) REFERENCES ec_event (event_id) ON DELETE CASCADE;

-- Case References require an index of the foreign key
CREATE INDEX ec_event_case_ref_idx1 ON ec_event_case_ref (event_id);




------------------------------------------------------------
-- Create BusinessResourceManager component schema
------------------------------------------------------------

/*
 * Create the tables used by BRM.   These tables are:
 *
 *	brm_schema_version
 *	brm_sequences
 *	brm_group_history
 *	brm_work_groups
 *	brm_work_item_offer
 *	brm_work_item_resources
 *	brm_work_items
 *	brm_work_item_data
 *	brm_work_item_data_snapshot
 *	brm_deployed_component
 *	brm_work_types
 *	brm_work_type_model
 *	brm_work_model
 *	brm_work_model_entity
 *	brm_work_model_entity_elem
 *	brm_work_model_spec
 *	brm_work_model_types
 *	brm_work_model_mapping
 */
/* Object:  Table brm_schema_version
 */
CREATE TABLE brm_schema_version
(
	major_vers		integer			NOT NULL,
	minor_vers		integer			NOT NULL,
	micro_vers		integer			NOT NULL,
	install_time	timestamp		NOT NULL,
	install_comment	varchar(255)		NULL,
	CONSTRAINT pk_brm_schema_version PRIMARY KEY (major_vers, minor_vers, micro_vers)
);

INSERT INTO brm_schema_version VALUES (1, 11, 0, CURRENT_TIMESTAMP, 'Initial install of BRM schema');





/* Object:  Table brm_seqeuences
 */
CREATE TABLE brm_sequences
(
	sequence_id	integer		NOT NULL,
	description	varchar(50)	NOT NULL,
	value		bigint		NOT NULL,
	CONSTRAINT pk_brm_sequences PRIMARY KEY (sequence_id)
);





/* Object:  Table brm_group_history
 */
CREATE TABLE brm_group_history
(
	group_id	bigint		NOT NULL,
	history_id	bigint		NOT NULL,
	resource_id	varchar(36)	NULL,
	org_entity	varchar(36)	NOT NULL,
	task_id		varchar(36)	NULL,
	CONSTRAINT pk_brm_group_history PRIMARY KEY (group_id, history_id)
);





/* Object:  Table brm_work_groups
 */
CREATE TABLE brm_work_groups
(
	group_id			bigint			NOT NULL,
	group_type			integer			NOT NULL,
	group_description	varchar (256)	NOT NULL,
	group_ended			boolean			NOT NULL,
	CONSTRAINT pk_brm_work_groups PRIMARY KEY (group_id)
);





/* Object:  Table brm_work_item_offer
*/
CREATE TABLE brm_work_item_offer
(
	work_item_id		bigint		NOT NULL,
	work_item_offer_id	bigint		NOT NULL,
	resource_id			varchar(36)	NOT NULL,
	entity_type			bigint			NULL,
	version				integer			NULL,
	CONSTRAINT pk_brm_work_item_offer PRIMARY KEY (work_item_id, work_item_offer_id)
);





/* Object:  Table brm_work_item_resources
 */
CREATE TABLE brm_work_item_resources
(
	work_item_id			bigint		NOT NULL,
	work_item_resource_id	bigint		NOT NULL,
	resource_id				varchar(36)	NOT NULL,
	entity_type				bigint			NULL,
	version					integer			NULL,
	CONSTRAINT pk_brm_work_item_resources PRIMARY KEY (work_item_id, work_item_resource_id)
);





/* Object:  Table brm_work_items
 */
CREATE TABLE brm_work_items
(
	work_item_id			bigint			NOT NULL,
	version					bigint			NOT NULL,
	priority				integer			NOT NULL,
	activity_id				varchar(1024)	NOT NULL,
	activity_name			varchar(1024)	NOT NULL,
	application_inst		varchar(1024)	NOT NULL,
	application_inst_desc	varchar(64)			NULL,
	application_name		varchar(1024)	NOT NULL,
	application_id			varchar(1024)	NOT NULL,
	work_item_name			varchar(64)		NOT NULL,
	description				varchar(256)		NULL,
	start_date				timestamp			NULL,
	target_date				timestamp			NULL,
	allocated				boolean			NOT NULL,
	state					integer			NOT NULL,
	visible					boolean			NOT NULL,
	group_id				bigint				NULL,
	work_type_id			bigint				NULL,
	work_model_id			bigint				NULL,
	brm_sequence_id			integer				NULL,
	ua_sequence_id			integer				NULL,
	entity_query			varchar(1024)		NULL,
	query_version			integer				NULL,
	attribute1				bigint				NULL,
	attribute2				varchar(64)			NULL,
	attribute3				varchar(64)			NULL,
	attribute4				varchar(64)			NULL,
	attribute5				decimal(38, 10)		NULL,
	attribute6				timestamp			NULL,
	attribute7				timestamp			NULL,
	attribute8				varchar(20)			NULL,
	attribute9				varchar(20)			NULL,
	attribute10				varchar(20)			NULL,
	attribute11				varchar(20)			NULL,
	attribute12				varchar(20)			NULL,
	attribute13				varchar(20)			NULL,
	attribute14				varchar(20)			NULL,
	attribute15				bigint				NULL,
	attribute16				decimal(38, 10)		NULL,
	attribute17				decimal(38, 10)		NULL,
	attribute18				decimal(38, 10)		NULL,
	attribute19				timestamp			NULL,
	attribute20				timestamp			NULL,
	attribute21				varchar(20)		NULL,
	attribute22				varchar(20)		NULL,
	attribute23				varchar(20)		NULL,
	attribute24				varchar(20)		NULL,
	attribute25				varchar(20)		NULL,
	attribute26				varchar(20)		NULL,
	attribute27				varchar(64)		NULL,
	attribute28				varchar(64)		NULL,
	attribute29				varchar(64)		NULL,
	attribute30				varchar(64)		NULL,
	attribute31				varchar(64)		NULL,
	attribute32				varchar(64)		NULL,
	attribute33				varchar(64)		NULL,
	attribute34				varchar(64)		NULL,
	attribute35				varchar(64)		NULL,
	attribute36				varchar(64)		NULL,
	attribute37				varchar(64)		NULL,
	attribute38				varchar(64)		NULL,
	attribute39				varchar(255)		NULL,
	attribute40				varchar(255)		NULL,
	autostartdate			boolean				NOT NULL,
	rescheduled				boolean				DEFAULT false NOT NULL,
	
	CONSTRAINT pk_brm_work_items PRIMARY KEY (work_item_id)
);





/* Object:  Table brm_work_item_alloc_history
 */
CREATE TABLE brm_work_item_alloc_history
(
	work_item_id			bigint		NOT NULL,
	allocation_history_id	bigint		NOT NULL,
	resource_id				varchar(36)	NOT NULL,
	allocation_date			timestamp	NOT NULL,
	CONSTRAINT pk_brm_work_item_alloc_history PRIMARY KEY (work_item_id, allocation_history_id)
);





-- Object:  TABLE brm_work_item_fields
--
CREATE TABLE brm_work_item_fields
(
	work_item_id	bigint			NOT NULL,
	field_id		bigint			NOT NULL,
	field_name		varchar(256)	NOT NULL,
	field_type		varchar(256)		NULL,
	is_array		boolean				NULL,
	CONSTRAINT pk_work_item_fields PRIMARY KEY (work_item_id, field_id)
);





-- Object:  TABLE brm_work_item_field_values
--
CREATE TABLE brm_work_item_field_values
(
	work_item_id	bigint		NOT NULL,
	field_id		bigint		NOT NULL,
	position		integer		NOT NULL,
	field_value		text			NULL,
	go_ref			varchar(450)	NULL,
	CONSTRAINT pk_work_item_field_values PRIMARY KEY (work_item_id, field_id, position)
);





-- Object:  Table work_item_fields_snapshot
--
CREATE TABLE brm_work_item_fields_snapshot
(
	work_item_id	bigint			NOT NULL,
	field_id		bigint			NOT NULL,
	field_name		varchar(256)	NOT NULL,
	field_type		varchar(256)		NULL,
	is_array		boolean				NULL,
	CONSTRAINT pk_work_item_fields_snapshot PRIMARY KEY (work_item_id, field_id)
);

-- Object:  Table brm_work_item_field_val_snap
-- 
CREATE TABLE brm_work_item_field_val_snap
(
	work_item_id	bigint		NOT NULL,
	field_id		bigint		NOT NULL,
	position		integer		NOT NULL,
	field_value		text			NULL,
	go_ref			varchar(450)	NULL,
	CONSTRAINT pk_brm_work_item_field_val_snap PRIMARY KEY (work_item_id, field_id, position)
);







/* Object:	Table brm_work_item_events
 */
CREATE TABLE brm_work_item_events
(
	work_item_id	bigint		NOT NULL,
	event_type		integer		NOT NULL,
	event_date		timestamp	NOT NULL,
	event_data		varchar(256)	NULL,
	CONSTRAINT pk_brm_work_item_events PRIMARY KEY (work_item_id, event_type)
);





/* Object:  Table brm_deployment_component
 */
CREATE TABLE brm_deployed_component
(
	id        		bigint			NOT NULL,
	name			varchar(1024)	NOT NULL,
	app_name		varchar(1024)	NOT NULL,
	major_vers		integer			NOT NULL,
	minor_vers		integer			NOT NULL,
	micro_vers		integer			NOT NULL,
	qualifier		varchar(36)			NULL,
	state			integer			NOT	NULL,
	CONSTRAINT pk_brm_deployed_component PRIMARY KEY (id)
);





/* Object:  Table brm_work_types
 */
CREATE TABLE brm_work_types
(
	work_type_id			bigint			NOT NULL,
	work_type_uid			varchar(36)		NOT NULL,
	major_vers				integer			NOT NULL,
	minor_vers				integer			NOT NULL,
	micro_vers				integer			NOT NULL,
	qualifier				varchar(36)			NULL,
	work_type_desc			varchar(256) 		NULL,
	is_piled				boolean			NOT NULL,
	piling_limit			integer				NULL,
	state					integer				NULL,
	ignore_incoming_data	boolean			DEFAULT true NOT NULL,
	reoffer_close			boolean			DEFAULT false NOT NULL,
	reoffer_cancel			boolean			DEFAULT true NOT NULL,
	app_id      			bigint			NOT NULL,
	CONSTRAINT pk_brm_work_types PRIMARY KEY (work_type_id)
);





/* Object:  Table brm_work_type_model
 */
CREATE TABLE brm_work_type_model
(
	work_type_id	bigint			NOT NULL,
	param_name		varchar(256)	NOT NULL,
	param_type		varchar(256)	NOT NULL,
	inout_type		integer			NOT NULL,
	default_value	text	 		NULL,
	optional		boolean			NOT NULL,
	is_array		boolean			NOT NULL,
	CONSTRAINT pk_brm_work_type_model PRIMARY KEY (work_type_id, param_name)
);





/* Object:  Table brm_work_type_model_simple
 */
CREATE TABLE brm_work_type_model_simple
(
	work_type_id	bigint			NOT NULL,
	param_name		varchar(256)	NOT NULL,
	param_length	varchar(256)	,
	param_decimal	varchar(256)	,
	CONSTRAINT pk_brm_work_type_model_simple PRIMARY KEY (work_type_id, param_name)
);





/* Object:  Table brm_work_type_model_complex
 */
CREATE TABLE brm_work_type_model_complex
(
	work_type_id	bigint			NOT NULL,
	param_name		varchar(256)	NOT NULL,
	class_name		varchar(256)	NOT NULL,
	CONSTRAINT pk_brm_work_type_model_complex PRIMARY KEY (work_type_id, param_name)
);





/* Object:  Table brm_work_model
 */
CREATE TABLE brm_work_model 
( 
	work_model_id		bigint 			NOT NULL,
	work_model_guid		varchar(36) 	NOT NULL,
	major_vers			integer			NOT NULL,
	minor_vers			integer			NOT NULL,
	micro_vers			integer			NOT NULL,
	qualifier			varchar(36)			NULL,
	org_model_version	integer				NULL,
	work_model_name		varchar(256)	NOT NULL,
	description			varchar(256) 		NULL,
	priority			integer			NOT NULL,
	entity_expression	varchar(1024),
	types_expression	varchar(1024),
	app_id  			bigint			NOT NULL,
	CONSTRAINT pk_brm_work_model PRIMARY KEY (work_model_id)
);





/* Object:  Table brm_work_model_entity
 */
CREATE TABLE brm_work_model_entity 
( 
	work_model_id			bigint			NOT NULL,
	work_model_entity_id	bigint			NOT NULL,
	allocated				boolean 		NOT NULL,
	entity_query			varchar(1024)		NULL,
	query_version			integer				NULL,
	CONSTRAINT pk_work_model_entity PRIMARY KEY (work_model_entity_id)
);





/* Object:  Table brm_work_model_entity_elem
 */
CREATE TABLE brm_work_model_entity_elem 
( 
	work_model_entity_id	bigint 			NOT NULL,
	guid					varchar(36) 	NOT NULL,
	type					integer 		NOT NULL,
	version					integer 		NOT NULL,
	CONSTRAINT pk_brm_work_model_entities PRIMARY KEY (work_model_entity_id, guid)
);





/* Object:  Table brm_work_model_spec
 */
CREATE TABLE brm_work_model_spec 
( 
	work_model_id	bigint 			NOT NULL,
	param_name		varchar(256) 	NOT NULL,
	param_type		varchar(256) 	NOT NULL,
	inout_type		integer			NOT NULL,
	default_value	text	 		NULL,
	optional		boolean			NOT NULL,
	is_array		boolean			NOT NULL,
	CONSTRAINT pk_brm_work_model_spec PRIMARY KEY (work_model_id, param_name)
);





/* Object:  Table brm_work_model_spec_simple
 */
CREATE TABLE brm_work_model_spec_simple 
( 
	work_model_id	bigint 			NOT NULL,
	param_name		varchar(256) 	NOT NULL,
	param_length	varchar(256)	,
	param_decimal	varchar(256)	,
	CONSTRAINT pk_brm_work_model_spec_simple PRIMARY KEY (work_model_id, param_name)
);






/* Object:  Table brm_work_model_spec_simple
 */
CREATE TABLE brm_work_model_spec_complex 
( 
	work_model_id	bigint 			NOT NULL,
	param_name		varchar(256) 	NOT NULL,
	class_name		varchar(256)	NOT NULL,
	CONSTRAINT pk_brm_work_model_spec_complex PRIMARY KEY (work_model_id, param_name)
);





/* Object:  Table brm_work_model_types
 */
CREATE TABLE brm_work_model_types 
( 
	work_model_id		bigint 			NOT NULL,
	work_model_types_id	bigint 			NOT NULL,
	work_type_guid		varchar(36) 	NOT NULL,
	work_type_version	varchar(256)		NULL,
	work_type_id		bigint 			NOT NULL,
	CONSTRAINT pk_brm_work_model_types PRIMARY KEY (work_model_id, work_model_types_id)
);





/* Object:  Table brm_work_model_mapping
 */
CREATE TABLE brm_work_model_mapping 
( 
	work_model_types_id	bigint 			NOT NULL,
	type_param_name		varchar(256) 	NOT NULL,
	model_param_name	varchar(256) 	NULL,
	default_value		text			NULL,
	CONSTRAINT pk_brm_work_model_mapping PRIMARY KEY (work_model_types_id, type_param_name)
);





/* Object:  Table brm_work_model_script
 */
CREATE TABLE brm_work_model_script
(
	work_model_id				bigint			NOT NULL,
	script_operation			integer			NOT NULL,	
	script_type_guid			varchar(36)			NULL,	
	script_body					text				NULL,
	script_language				varchar(24)			NULL,		
	script_language_version		varchar(12)			NULL,		
	script_language_extension	varchar(3)			NULL,		
	CONSTRAINT pk_brm_work_model_script PRIMARY KEY (work_model_id, script_operation)
);





/* Object:  Table brm_script_types
 */
CREATE TABLE brm_script_types
(
	script_type_id		bigint		NOT NULL,	
	script_type_guid	varchar(36)	NOT NULL,
	major_vers			integer		NOT NULL,
	minor_vers			integer		NOT NULL,
	micro_vers			integer		NOT NULL,
	qualifier			varchar(36)		NULL,
	script_type			integer		DEFAULT 1 NOT NULL,
	script_type_xml		text			NULL,
	CONSTRAINT pk_brm_script_types PRIMARY KEY (script_type_id)
);





/* Object:	Table brm_org_entity_config
 */
CREATE TABLE brm_org_entity_config
(
	resource_id			varchar(36)		NOT NULL,
	CONSTRAINT pk_brm_org_entity_config PRIMARY KEY (resource_id)
);





/* Object:	Table brm_org_entity_config_attr
 */
CREATE TABLE brm_org_entity_config_attr
(
	resource_id			varchar(36)		NOT NULL,
	attribute_name		varchar(256)	NOT NULL,
	attribute_desc		varchar(1024) 		NULL,
	attribute_value		varchar(1024)		NULL,
	read_only			boolean			NOT NULL,
	private				boolean			NOT NULL,
	CONSTRAINT pk_brm_org_entity_config_attr PRIMARY KEY (resource_id, attribute_name)
);





/* Object:	Table brm_org_entity_stats
 */
CREATE TABLE brm_org_entity_stats
(
	resource_id			varchar(36)		NOT NULL,
	CONSTRAINT pk_brm_org_entity_stats PRIMARY KEY (resource_id)
);






/* Object:	Table outofsequence_messages
 */
CREATE TABLE brm_outofsequence_message
(
	work_item_id		bigint		NOT NULL,
	ua_sequence_id		integer		NOT NULL,
	ok_to_process		boolean		NOT NULL,
	message_type		integer		NOT NULL,
	message				text		NOT NULL,
	secsubject			bytea		NOT NULL,
	CONSTRAINT pk_outofsequence_message PRIMARY KEY (work_item_id, ua_sequence_id)
);


/* Object:  Table brm_work_view_authors
*/
CREATE TABLE brm_work_view_authors
(
	work_view_id		bigint		NOT NULL,
	work_view_author_id	bigint		NOT NULL,
	resource_id			varchar(36)	NOT NULL,
	entity_type			bigint			NULL,
	CONSTRAINT pk_brm_work_view_authors PRIMARY KEY (work_view_id, work_view_author_id)
);





/* Object:  Table brm_work_view_users
 */
CREATE TABLE brm_work_view_users
(
	work_view_id		bigint		NOT NULL,
	work_view_user_id	bigint		NOT NULL,
	resource_id			varchar(36)	NOT NULL,
	entity_type			bigint			NULL,
	CONSTRAINT pk_brm_work_view_users PRIMARY KEY (work_view_id, work_view_user_id)
);





/* Object:  Table brm_work_views
 */
CREATE TABLE brm_work_views
(
	work_view_id		bigint			NOT NULL,
	name				varchar(64)		NOT NULL,
	description			varchar(255)		NULL,
	creation_date		timestamp		NOT NULL,
	modification_date	timestamp		NOT NULL,
	owner_id			varchar(36)		NOT NULL,
	locker_id			varchar(36)			NULL,
	entity_id			varchar(36)			NULL,
	entity_type			bigint				NULL,
	view_type			varchar(36)		DEFAULT 'NORMAL' NOT NULL,
	view_order			varchar(1024)		NULL,
	view_filter			varchar(1024)		NULL,
	public_view			boolean			NOT	NULL,
	cust_data			text				NULL,
	CONSTRAINT pk_brm_work_views PRIMARY KEY (work_view_id)
);

CREATE TABLE brm_attribute_alias
(
	attribute_name			varchar(11)			NOT NULL,
 	major_vers				integer				NOT NULL,
	minor_vers				integer				NOT NULL,
	micro_vers				integer				NOT NULL,
	qualifier				varchar(36),
	display_name			varchar(64)
);

CREATE TABLE brm_orgnotification_queue
(
	message_id				bigint		NOT NULL,
	message_type			integer		NOT NULL,
	retry_count				integer		NOT NULL,
	retry_time				timestamp	NOT NULL,
	message					text		NOT NULL,
	payload					bytea		NOT NULL,
	CONSTRAINT pk_brm_orgnotification_queue PRIMARY KEY (message_id)
);

CREATE INDEX ix_brm_orgnotification_queue ON brm_orgnotification_queue (retry_count, retry_time);


/*
 * End of table creation
 */

/*
 * Now create the unique keys for each table
 */
ALTER TABLE brm_work_model_types ADD CONSTRAINT UK_brm_work_model_types UNIQUE (work_model_types_id);

/*
 * Now create the foreign key constraints for each table
 */
ALTER TABLE brm_group_history ADD CONSTRAINT fk_brm_group_history FOREIGN KEY (group_id) REFERENCES brm_work_groups (group_id) ON DELETE CASCADE;

ALTER TABLE brm_work_item_offer ADD CONSTRAINT fk_brm_work_item_offer FOREIGN KEY (work_item_id) REFERENCES brm_work_items (work_item_id);

ALTER TABLE brm_work_item_resources ADD CONSTRAINT fk_brm_work_item_resources FOREIGN KEY (work_item_id) REFERENCES brm_work_items (work_item_id);

ALTER TABLE brm_work_item_alloc_history ADD CONSTRAINT fk_brm_work_item_alloc_history FOREIGN KEY (work_item_id) REFERENCES brm_work_items (work_item_id);

ALTER TABLE brm_work_items ADD CONSTRAINT fk_brm_work_items_group_id FOREIGN KEY (group_id) REFERENCES brm_work_groups (group_id);

ALTER TABLE brm_work_items ADD CONSTRAINT fk_brm_work_items_work_type FOREIGN KEY (work_type_id) REFERENCES brm_work_types (work_type_id);

ALTER TABLE brm_work_item_fields ADD CONSTRAINT fk_work_item_fields FOREIGN KEY (work_item_id) REFERENCES brm_work_items (work_item_id);

ALTER TABLE brm_work_item_field_values ADD CONSTRAINT fk_work_item_field_values FOREIGN KEY (work_item_id, field_id) REFERENCES brm_work_item_fields (work_item_id, field_id);

ALTER TABLE brm_work_item_fields_snapshot ADD CONSTRAINT fk_work_item_fields_snapshot FOREIGN KEY (work_item_id) REFERENCES brm_work_items (work_item_id);

ALTER TABLE brm_work_item_field_val_snap ADD CONSTRAINT fk_work_item_field_val_snap FOREIGN KEY (work_item_id, field_id) REFERENCES brm_work_item_fields_snapshot (work_item_id, field_id);

ALTER TABLE brm_work_types ADD CONSTRAINT fk_brm_work_types FOREIGN KEY (app_id) REFERENCES brm_deployed_component (id) ON DELETE CASCADE;

ALTER TABLE brm_work_type_model ADD CONSTRAINT fk_brm_work_type_model FOREIGN KEY (work_type_id) REFERENCES brm_work_types (work_type_id) ON DELETE CASCADE;

ALTER TABLE brm_work_type_model_simple ADD CONSTRAINT fk_brm_work_type_model_simple FOREIGN KEY (work_type_id, param_name) REFERENCES brm_work_type_model (work_type_id, param_name) ON DELETE CASCADE;

ALTER TABLE brm_work_type_model_complex ADD CONSTRAINT fk_brm_work_type_model_complex FOREIGN KEY (work_type_id, param_name) REFERENCES brm_work_type_model (work_type_id, param_name) ON DELETE CASCADE;

ALTER TABLE brm_work_model ADD CONSTRAINT fk_brm_work_model FOREIGN KEY (app_id) REFERENCES brm_deployed_component (id) ON DELETE CASCADE;

ALTER TABLE brm_work_model_entity ADD CONSTRAINT fk_brm_wm_entity_wm FOREIGN KEY (work_model_id) REFERENCES brm_work_model (work_model_id) ON DELETE CASCADE;

ALTER TABLE brm_work_model_entity_elem ADD CONSTRAINT fk_brm_wm_ent_elem_wm_entity FOREIGN KEY (work_model_entity_id) REFERENCES brm_work_model_entity (work_model_entity_id) ON DELETE CASCADE;

ALTER TABLE brm_work_model_spec ADD CONSTRAINT fk_brm_wm_specification_wm FOREIGN KEY (work_model_id) REFERENCES brm_work_model (work_model_id) ON DELETE CASCADE;

ALTER TABLE brm_work_model_spec_simple ADD CONSTRAINT fk_brm_work_model_spec_simple FOREIGN KEY (work_model_id, param_name) REFERENCES brm_work_model_spec (work_model_id, param_name) ON DELETE CASCADE;

ALTER TABLE brm_work_model_spec_complex ADD CONSTRAINT fk_brm_work_model_spec_complex FOREIGN KEY (work_model_id, param_name) REFERENCES brm_work_model_spec (work_model_id, param_name) ON DELETE CASCADE;

ALTER TABLE brm_work_model_types ADD CONSTRAINT fk_brm_wm_types_wm FOREIGN KEY (work_model_id) REFERENCES brm_work_model (work_model_id) ON DELETE CASCADE;

ALTER TABLE brm_work_model_types ADD CONSTRAINT fk_brm_wm_types_work_types FOREIGN KEY (work_type_id) REFERENCES brm_work_types (work_type_id)	ON DELETE CASCADE;

ALTER TABLE brm_work_model_mapping ADD CONSTRAINT fk_brm_wm_mapping_wm_types FOREIGN KEY (work_model_types_id) REFERENCES brm_work_model_types (work_model_types_id) ON DELETE CASCADE;

ALTER TABLE brm_work_model_script ADD CONSTRAINT fk_brm_wm_script_wm FOREIGN KEY (work_model_id) REFERENCES brm_work_model (work_model_id) ON DELETE CASCADE;

ALTER TABLE brm_org_entity_config_attr ADD CONSTRAINT fk_brm_org_entity_config_attr FOREIGN KEY (resource_id) REFERENCES brm_org_entity_config (resource_id) ON DELETE CASCADE;

ALTER TABLE brm_work_view_authors ADD CONSTRAINT fk_brm_work_view_author FOREIGN KEY (work_view_id) REFERENCES brm_work_views (work_view_id) ON DELETE CASCADE;

ALTER TABLE brm_work_view_users ADD CONSTRAINT fk_brm_work_view_users FOREIGN KEY (work_view_id) REFERENCES brm_work_views (work_view_id) ON DELETE CASCADE;

/*
 * End of foreign key constraint creation
 */




/*
 * Create the indexes for each table
 */
CREATE INDEX ix_brm_work_item_resources ON brm_work_item_resources (resource_id);

CREATE INDEX ix_brm_work_item_offer ON brm_work_item_offer (resource_id);

CREATE INDEX ix_brm_work_items_A ON brm_work_items (priority, start_date, target_date, work_item_name);

CREATE INDEX ix_brm_work_items_B ON brm_work_items (application_inst_desc, attribute1, attribute2, attribute3, attribute4);

CREATE INDEX ix_brm_work_items_C ON brm_work_items (visible, priority);

CREATE INDEX ix_brm_work_items_work_type ON brm_work_items (work_type_id);

CREATE INDEX ix_brm_work_types ON brm_work_types (work_type_uid);

CREATE INDEX ix_brm_work_types_id ON brm_work_types (app_id);

CREATE INDEX ix_brm_work_groups ON brm_work_groups (group_id, group_type);

CREATE INDEX ix_brm_group_history ON brm_group_history (resource_id, group_id);

CREATE INDEX ix_brm_work_item_field_values ON brm_work_item_field_values (go_ref);

CREATE INDEX ix_brm_work_items_gid ON brm_work_items(group_id);

CREATE INDEX ix_brm_work_items_wtid ON brm_work_items(work_type_id);

CREATE INDEX ix_brm_work_model ON brm_work_model (app_id);

CREATE INDEX ix_brm_work_model_entity ON brm_work_model_entity(work_model_id);

CREATE INDEX ix_brm_work_model_types ON brm_work_model_types(work_type_id);

/*
 * End of index creation
 */

/*
 * Populate the sequence table
 */
INSERT INTO brm_sequences VALUES (1, 'WorkModel', 1);
INSERT INTO brm_sequences VALUES (2, 'WorkGroup', 1);
INSERT INTO brm_sequences VALUES (3, 'WorkType', 1);
INSERT INTO brm_sequences VALUES (4, 'WorkModelBRM', 1);
INSERT INTO brm_sequences VALUES (5, 'WorkModelEntityBRM', 1);
INSERT INTO brm_sequences VALUES (6, 'WorkModelTypesBRM', 1);
INSERT INTO brm_sequences VALUES (7, 'ScriptTypesBRM', 1);
INSERT INTO brm_sequences VALUES (8, 'WorkView', 1);
INSERT INTO brm_sequences VALUES (9, 'OrgNotification', 1);

/* 
 * Create the views used by BRM.   These view are:
 *
 *	work_items_no_data
 *
 */
/*
 * Object:  View brm_work_items_no_data
 */
CREATE OR REPLACE VIEW brm_work_items_no_data
AS
SELECT	brm_work_items.work_item_id, brm_work_items.version, brm_work_items.priority,
		brm_work_items.activity_id, brm_work_items.activity_name, brm_work_items.application_inst, brm_work_items.application_inst_desc, brm_work_items.application_name, brm_work_items.application_id,
		brm_work_items.work_item_name, brm_work_items.description, brm_work_items.start_date, brm_work_items.target_date, brm_work_items.allocated,
		brm_work_items.state, brm_work_items.visible, brm_work_items.group_id, brm_work_items.work_type_id, 
		brm_work_items.work_model_id, brm_work_items.brm_sequence_id, brm_work_items.ua_sequence_id, 
		brm_work_items.entity_query, brm_work_items.query_version, brm_work_items.attribute1, brm_work_items.attribute2, brm_work_items.attribute3, 
		brm_work_items.attribute4, brm_work_items.attribute5,  brm_work_items.attribute6, brm_work_items.attribute7, brm_work_items.attribute8, 
		brm_work_items.attribute9, brm_work_items.attribute10, brm_work_items.attribute11,
		brm_work_items.attribute12, brm_work_items.attribute13, brm_work_items.attribute14,
		brm_work_items.attribute15, brm_work_items.attribute16, brm_work_items.attribute17,
		brm_work_items.attribute18, brm_work_items.attribute19, brm_work_items.attribute20,
		brm_work_items.attribute21, brm_work_items.attribute22, brm_work_items.attribute23,
		brm_work_items.attribute24, brm_work_items.attribute25, brm_work_items.attribute26,
		brm_work_items.attribute27, brm_work_items.attribute28, brm_work_items.attribute29,
		brm_work_items.attribute30, brm_work_items.attribute31, brm_work_items.attribute32,
		brm_work_items.attribute33, brm_work_items.attribute34, brm_work_items.attribute35,
		brm_work_items.attribute36, brm_work_items.attribute37, brm_work_items.attribute38,
		brm_work_items.attribute39, brm_work_items.attribute40,
		brm_work_items.autostartdate, brm_work_items.rescheduled,  brm_work_item_resources.resource_id
FROM	brm_work_item_resources INNER JOIN
		brm_work_items ON brm_work_item_resources.work_item_id = brm_work_items.work_item_id;



/*
 * Object:  View brm_group_view
 */
CREATE OR REPLACE VIEW brm_group_view
AS
SELECT	brm_work_groups.group_id, brm_work_groups.group_type, brm_work_groups.group_description, brm_group_history.history_id, 
		brm_group_history.resource_id, brm_group_history.org_entity
FROM	brm_group_history INNER JOIN
		brm_work_groups ON brm_group_history.group_id = brm_work_groups.group_id;



/*
 * End of view creation
 */




------------------------------------------------------------
-- Create Calendar component schema
------------------------------------------------------------


CREATE TABLE dac_schema_version
(
	major_vers		integer						NOT NULL,
	minor_vers		integer						NOT NULL,
	micro_vers		integer						NOT NULL,
	install_time	timestamp with time zone	NOT NULL,
	install_comment varchar(255)				NULL,
	CONSTRAINT dac_schema_version_pk PRIMARY KEY (major_vers, minor_vers, micro_vers)
);

INSERT INTO dac_schema_version VALUES (1, 11, 0, CURRENT_TIMESTAMP, 'Initial install of DAC schema');

CREATE TABLE dac_workcalendar
(
  id              bigint 					NOT NULL,
  concurrency     integer 					DEFAULT 0,
  namespace       varchar(400) 				NOT NULL DEFAULT ' ',
  name            varchar(50) 				NOT NULL,
  caltype         smallint 					DEFAULT 1,
  timezone        varchar(50) 				NULL,
  minhours        integer 					NOT NULL DEFAULT 1,
  datecreated     timestamp with time zone 	NOT NULL,
  datemodified    timestamp with time zone 	NULL,
  CONSTRAINT cal_workcal_pk PRIMARY KEY (id),
  CONSTRAINT cal_workcal_owner_uq UNIQUE (namespace, name)
);

INSERT INTO dac_workcalendar (id, concurrency, namespace, name, caltype, datecreated) VALUES (0, 0, ' ', 'SYSTEM', 1, CURRENT_TIMESTAMP);

CREATE TABLE dac_workingday
(
  calendar_id     bigint 			NOT NULL,
  day_of_week     char(2) 			NOT NULL,
  start1          integer 			NULL,
  end1            integer 			NULL,
  duration1       varchar(40) 		NULL,
  start2          integer 			NULL,
  end2            integer 			NULL,
  duration2       varchar(40) 		NULL,
  start3          integer 			NULL,
  end3            integer 			NULL,
  duration3       varchar(40) 		NULL,
  start4          integer 			NULL,
  end4            integer 			NULL,
  duration4       varchar(40) 		NULL,
  start5          integer 			NULL,
  end5            integer 			NULL,
  duration5       varchar(40) 		NULL,
  CONSTRAINT dac_workday_pk PRIMARY KEY (calendar_id, day_of_week),
  CONSTRAINT dac_workcal_day_fk FOREIGN KEY (calendar_id) REFERENCES dac_workcalendar(id) ON DELETE CASCADE
);

CREATE TABLE dac_workingdayexclusion
(
  guid            varchar(36)				NOT NULL,
  concurrency     integer 					DEFAULT 0,
  calendar_id     bigint 					NOT NULL,
  excltype        smallint 					DEFAULT 0,
  description     varchar(1024) 			NULL,
  startDate       timestamp with time zone 	NULL,
  endDate         timestamp with time zone 	NULL,
  allDay          boolean 					DEFAULT false,
  freebusy        smallint 					DEFAULT 2,
  rrule           varchar(1024) 			NULL,
  duration        varchar(40) 				NULL,

  CONSTRAINT dac_workdayex_pk PRIMARY KEY (guid),
  CONSTRAINT dac_workdayex_fk FOREIGN KEY (calendar_id) REFERENCES dac_workcalendar(id) ON DELETE CASCADE
);
CREATE INDEX de_workdayex_calendar ON dac_workingdayexclusion (calendar_id);

CREATE TABLE dac_calendarref
(
  calendar_id     bigint 		NOT NULL,
  reference_guid  varchar(50)	NOT NULL,
  
  CONSTRAINT dac_calref_pk PRIMARY KEY (calendar_id, reference_guid),
  CONSTRAINT dac_calref_fk FOREIGN KEY (calendar_id) REFERENCES dac_workcalendar(id) ON DELETE CASCADE
);

/* Holds sequence numbers used for various entities in DAC */
CREATE TABLE dac_sequences
(
  sequence_id		bigint 		NOT NULL,
  description		varchar(50) NOT NULL,
  value				bigint 		NOT NULL,
  CONSTRAINT cal_sequences_pk PRIMARY KEY (sequence_id)
);

INSERT INTO dac_sequences (sequence_id, description, value) VALUES (1, 'workcalendar', 1);




------------------------------------------------------------
-- Create DirectoryEngine component schema
------------------------------------------------------------


CREATE TABLE de_schema_version
(
    major_vers      integer         NOT NULL,
    minor_vers      integer         NOT NULL,
    micro_vers      integer         NOT NULL,
    install_time    timestamp with time zone       NOT NULL,
    install_comment varchar(255)        NULL,
    CONSTRAINT de_schema_version_pk PRIMARY KEY (major_vers, minor_vers, micro_vers)
);

INSERT INTO de_schema_version VALUES (1, 11, 0, CURRENT_TIMESTAMP, 'Initial install of DE schema');

CREATE TABLE de_deployed_component
(
    name            varchar(1024)   NOT NULL,
    app_name        varchar(1024)   NOT NULL,
    major_vers      integer         NOT NULL,
    minor_vers      integer         NOT NULL,
    micro_vers      integer         NOT NULL,
    qualifier       varchar(256)    NULL,
    state           integer         NOT NULL
);


CREATE TABLE de_entitytype
(
    id              bigint NOT NULL,
    name            varchar(256) NOT NULL,
    CONSTRAINT de_entitytype_pk PRIMARY KEY (id),
    CONSTRAINT de_entitytype_name_uq UNIQUE (name) 
);

CREATE TABLE de_iterator
(
    entitytype_id   bigint NOT NULL,
    entity_guid     varchar(36) NOT NULL,
    prev_resource   bigint NOT NULL,

    CONSTRAINT de_iterator_pk PRIMARY KEY (entitytype_id, entity_guid),
    CONSTRAINT de_entitytype_fk FOREIGN KEY (entitytype_id) REFERENCES de_entitytype(id) ON DELETE CASCADE
);

-- DO NOT CHANGE THE COLUMNS OF THIS TABLE
-- IT WILL CAUSE MAJOR PROBLEMS IN RELEASE UPDATES
CREATE TABLE de_deployedartefact
(
    id              bigint,
    majorversion    integer NOT NULL,
    minorversion    integer NOT NULL,
    microversion    integer NOT NULL,
    qualifier       varchar(256) NULL,
    versionname     varchar(256) NULL,
    datecreated     timestamp with time zone NOT NULL,
    datemodified    timestamp with time zone NULL,
    deploydate      timestamp with time zone NULL,
    deployer        varchar(256) NULL,
    active          boolean DEFAULT true,
    concurrency     integer DEFAULT 0,
    schemaversion   integer DEFAULT 1,
    source          text NOT NULL,

    CONSTRAINT de_deployedartefact_pk PRIMARY KEY (id),
    CONSTRAINT de_deployedartefact_vers_uq UNIQUE (majorversion, minorversion, microversion, qualifier)
);

CREATE TABLE de_resource
(
    id               bigint NOT NULL,
    concurrency      integer DEFAULT 0,
    resourcetype     char DEFAULT 'H',
    guid             varchar(36) NOT NULL,
    name             varchar(256) NOT NULL,
    displayname      varchar(256) NULL,
    description      varchar(1000) NULL,
    ldapcontainer_id bigint NULL,
    primaryalias     varchar(256) NOT NULL,
    primarydn        varchar(2000) NOT NULL,
    primaryhash      integer DEFAULT 0 NOT NULL,
    startdate        timestamp with time zone NULL,
    enddate          timestamp with time zone NULL,
    location_guid    varchar(36) NULL,
    cost             bigint NULL,
    costcurrency     varchar(20) NULL,
    unitcost         integer NULL,
    consumptionrate  numeric(26,4) DEFAULT 0,
    capacity         numeric(26,4) DEFAULT 0,
    unitmeasure      integer NULL,
    unittime         integer NULL,
    lastverified     timestamp with time zone NULL,
    updated			 timestamp with time zone DEFAULT CLOCK_TIMESTAMP() NOT NULL,
    
    CONSTRAINT de_rsrc_pk PRIMARY KEY (id),
    CONSTRAINT de_rsrc_guid_uq UNIQUE (guid)
);
CREATE INDEX de_resource_name ON de_resource (name);
CREATE INDEX de_rsrc_ldaphash ON de_resource (primaryhash);
CREATE INDEX de_rsrc_dates ON de_resource (startdate, enddate, id);
CREATE INDEX de_rsrc_enddate ON de_resource (enddate);

-- used to record deleted BPM users
CREATE TABLE de_delresource
(
    id               bigint NOT NULL,
    concurrency      integer,
    resourcetype     char,
    guid             varchar(36) NOT NULL,
    name             varchar(256) NOT NULL,
    displayname      varchar(256) NULL,
    ldapcontainer_id bigint NULL,
    primaryalias     varchar(256) NOT NULL,
    primarydn        varchar(2000) NOT NULL,
    primaryhash      integer NOT NULL,
    deletedate       timestamp with time zone DEFAULT CLOCK_TIMESTAMP() NOT NULL,
    
    CONSTRAINT de_delrsrc_pk PRIMARY KEY (id),
    CONSTRAINT de_delrsrc_guid_uq UNIQUE (guid)
);
CREATE INDEX de_delrsrc_name ON de_delresource (name);
CREATE INDEX de_delrsrc_ldaphash ON de_delresource (primaryhash);

CREATE FUNCTION remove_inserted_resource() RETURNS trigger AS
$remove_inserted_resource$
BEGIN
   DELETE FROM de_delresource WHERE guid=NEW.guid;
   RETURN NEW;
END;
$remove_inserted_resource$ LANGUAGE plpgsql;
CREATE TRIGGER de_insertresource AFTER INSERT ON de_resource FOR EACH ROW EXECUTE PROCEDURE remove_inserted_resource();

CREATE FUNCTION copy_deleted_resource() RETURNS trigger AS
$copy_deleted_resource$
BEGIN
   INSERT INTO de_delresource (id, concurrency, resourcetype, guid, name, displayname, ldapcontainer_id, primaryalias, primarydn, primaryhash)
   VALUES(OLD.id, OLD.concurrency, OLD.resourcetype, OLD.guid, OLD.name, OLD.displayname, OLD.ldapcontainer_id, OLD.primaryalias, OLD.primarydn, OLD.primaryhash);
   RETURN OLD;
END;
$copy_deleted_resource$ LANGUAGE plpgsql;
CREATE TRIGGER de_deleteresource AFTER DELETE ON de_resource FOR EACH ROW EXECUTE PROCEDURE copy_deleted_resource();

CREATE TABLE de_attributeheld
(
    resource_id      bigint NOT NULL,
    attrtype_guid    varchar(36) NOT NULL,
    barevalue        varchar(400) NOT NULL,
    normvalue        varchar(400) NOT NULL,

    CONSTRAINT de_attrheld_pk PRIMARY KEY (resource_id, attrtype_guid, normvalue),
    CONSTRAINT de_attrheld_fk FOREIGN KEY (resource_id) REFERENCES de_resource(id) ON DELETE CASCADE
);

-- records the relationship between a resource and a group
CREATE TABLE de_groupheld
(
    resource_id      bigint NOT NULL,
    group_guid       varchar(36) NOT NULL,
    startdate        timestamp with time zone NULL,
    enddate          timestamp with time zone NULL,

    CONSTRAINT de_grpheld_pk PRIMARY KEY (resource_id, group_guid),
    CONSTRAINT de_grpheld_fk FOREIGN KEY (resource_id) REFERENCES de_resource(id) ON DELETE CASCADE
);

-- records the relationship between a resource and a position
CREATE TABLE de_positionheld
(
    resource_id      bigint NOT NULL,
    position_guid    varchar(36) NOT NULL,
    orgunit_guid     varchar(36) NOT NULL,
    org_guid         varchar(36) NOT NULL,
    startdate        timestamp with time zone NULL,
    enddate          timestamp with time zone NULL,

    CONSTRAINT de_posheld_pk PRIMARY KEY (resource_id, position_guid),
    CONSTRAINT de_posheld_fk FOREIGN KEY (resource_id) REFERENCES de_resource(id) ON DELETE CASCADE
);

-- records the relationship between a resource and a capability
-- if a capability can hold many qualifying values
-- there will be many entries for the same capability guid
CREATE TABLE de_capabilityheld
(
    resource_id      bigint NOT NULL,
    majorversion     integer NOT NULL,
    capability_guid  varchar(36) NOT NULL,
    barevalue        varchar(400) NULL,
    normvalue        varchar(400) NOT NULL,

    CONSTRAINT de_capheld_pk PRIMARY KEY (resource_id, majorversion, capability_guid, normvalue),
    CONSTRAINT de_capheld_fk FOREIGN KEY (resource_id) REFERENCES de_resource(id) ON DELETE CASCADE
);

-- records those properties of org-model entities not included in deployment artefacts.
CREATE TABLE de_entityprops
(
    concurrency      integer DEFAULT 0,
    majorversion     integer NOT NULL,
    entity_guid      varchar(36) NOT NULL,
    calendar_alias   varchar(256) NULL,

    CONSTRAINT de_entprops_pk PRIMARY KEY (majorversion, entity_guid)
);

-- records channels through which work can be 'pushed' to resources
CREATE TABLE de_pushdestination
(
    id               bigint NOT NULL,
    concurrency      integer DEFAULT 0,
    majorversion     integer NOT NULL,
    name             varchar(256) NULL,
    holder_guid      varchar(36) NOT NULL,
    channel_type     varchar(2000) NOT NULL, 
    channel_id       varchar(2000) NOT NULL,
    local_value      varchar(2000) NULL,
    attrtype_guid    varchar(36) NULL,
    enabled          boolean DEFAULT true,

    CONSTRAINT de_pushdest_pk PRIMARY KEY (id)
);
CREATE INDEX de_pushdest_holder ON de_pushdestination (majorversion,holder_guid);

-- records a resource's connection to secondary ldap source entries
CREATE TABLE de_ldaporigin
(
    resource_id      bigint NOT NULL,
    ldapalias        varchar(256) NOT NULL,
    ldapdn           varchar(2000) NOT NULL,
    hash             integer DEFAULT 0 NULL,

    CONSTRAINT de_ldaporigin_pk PRIMARY KEY (resource_id, ldapalias),
    CONSTRAINT de_ldap_resource_fk FOREIGN KEY (resource_id) REFERENCES de_resource(id) ON DELETE CASCADE
);

CREATE TABLE de_ldapcontainer
(
    id               bigint NOT NULL,
    concurrency      integer DEFAULT 0,
    name             varchar(256) NOT NULL,
    description      varchar(1000) NULL,
    resourcecount    integer DEFAULT 0,
    lastaccess       timestamp with time zone NOT NULL,
    active           boolean DEFAULT true,

    CONSTRAINT de_ldapcntnr_pk PRIMARY KEY (id),
    CONSTRAINT de_ldapcntnr_name_uq UNIQUE (name)
);

CREATE TABLE de_ldaporganisation
(
    container_id     bigint NOT NULL,
    org_guid         varchar(36) NOT NULL,

    CONSTRAINT de_ldaporg_pk PRIMARY KEY (container_id, org_guid),
    CONSTRAINT de_ldaporg_fk FOREIGN KEY (container_id) REFERENCES de_ldapcontainer(id) ON DELETE CASCADE
);

CREATE TABLE de_ldapsource
(
    id               bigint NOT NULL,
    concurrency      integer DEFAULT 0,
    guid             varchar(36) NOT NULL,
    container_id     bigint NOT NULL,
    ldapalias        varchar(256) NOT NULL,
    isprimary        boolean DEFAULT true,
    basedn           varchar(2000) NULL,
    searchstring     varchar(4000) NULL,
    resourcename     varchar(2000) NULL,
    searchscope      integer DEFAULT 2,
    groupdn          varchar(2000) NULL,
    memberattr       varchar(50) NULL,
    category         integer DEFAULT 1,

    CONSTRAINT de_ldapsrc_pk PRIMARY KEY (id),
    CONSTRAINT de_ldapsrc_fk FOREIGN KEY (container_id) REFERENCES de_ldapcontainer(id) ON DELETE CASCADE
);
CREATE INDEX de_ldapsrc_container ON de_ldapsource(container_id);

CREATE TABLE de_ldapprimarylink
(
    secondary_id     bigint NOT NULL,
    primaryattr      varchar(50) NOT NULL,
    secondaryattr    varchar(50) NOT NULL,

    CONSTRAINT de_ldaplink_pk PRIMARY KEY (secondary_id, primaryattr),
    CONSTRAINT de_ldaplink_fk FOREIGN KEY (secondary_id) REFERENCES de_ldapsource(id) ON DELETE CASCADE
);

CREATE TABLE de_ldapattrlink
(
    container_id     bigint NOT NULL,
    source_id        bigint NOT NULL,
    attrtype_guid    varchar(36) NOT NULL,
    ldapattr         varchar(50) NOT NULL,

    -- primary key should be container_id not source_id
    -- but Hibernate causes a duplicate key error due to the way it processes updates
    CONSTRAINT de_ldapattrlink_pk PRIMARY KEY (source_id, attrtype_guid),
    CONSTRAINT de_ldapattrlink1_fk FOREIGN KEY (container_id) REFERENCES de_ldapcontainer(id) ON DELETE CASCADE,
    CONSTRAINT de_ldapattrlink2_fk FOREIGN KEY (source_id) REFERENCES de_ldapsource(id) ON DELETE CASCADE
);
CREATE INDEX de_ldapattr_container ON de_ldapattrlink(container_id);

-- records the ldap query used to populate positions and groups
CREATE TABLE de_candidatequery
(
    entity_guid      varchar(36) NOT NULL,
    concurrency      integer DEFAULT 0,
    isabstract       boolean DEFAULT false,
    isdynamic        boolean DEFAULT false,
    container_id     bigint NOT NULL,
    basedn           varchar(2000) NULL,
    searchstring     varchar(4000) NULL,
    searchscope      integer DEFAULT 2,

    CONSTRAINT de_candidatequery_pk PRIMARY KEY (entity_guid),
    CONSTRAINT de_candidatequery_fk FOREIGN KEY (container_id) REFERENCES de_ldapcontainer(id) ON DELETE CASCADE
);

-- records the ldap query that governs the instantiation of org-model template
CREATE TABLE de_extensionpoint
(
    id               bigint NOT NULL,
    concurrency      integer DEFAULT 0,
    majorversion     integer NOT NULL,
    holder_guid      varchar(36) NOT NULL,
    ldapalias        varchar(256) NOT NULL,
    basedn           varchar(2000) NULL,
    searchstring     varchar(4000) NOT NULL,
    searchscope      integer DEFAULT 2,
    ldapattr         varchar(50) NOT NULL,

    CONSTRAINT de_extpoint_pk PRIMARY KEY (id),
    CONSTRAINT de_extpoint_uq UNIQUE (majorversion, holder_guid)
);

-- maps the Instance Identity Attributes from their model names to LDAP attribute names
CREATE TABLE de_extidentityattrs
(
    parent_id        bigint NOT NULL,
    modelname        varchar(50) NOT NULL,
    ldapname         varchar(50) NOT NULL,

    CONSTRAINT de_extidattr_pk PRIMARY KEY (parent_id, modelname),
    CONSTRAINT de_extidattr_fk FOREIGN KEY (parent_id) REFERENCES de_extensionpoint(id) ON DELETE CASCADE
);

-- records the instantiation of org-model template
CREATE TABLE de_extensioninstance
(
    majorversion     integer NOT NULL,
    instance_guid    varchar(36) NOT NULL,
    concurrency      integer DEFAULT 0,
    parent_id        bigint NOT NULL,
    ldapdn           varchar(2000) NOT NULL,
    ldapattrvalue    varchar(256) NOT NULL,
    checksum         bigint NOT NULL,
    model            bytea NOT NULL,

    CONSTRAINT de_extinst_pk PRIMARY KEY (majorversion, instance_guid),
    CONSTRAINT de_extinst_fk FOREIGN KEY (parent_id) REFERENCES de_extensionpoint(id) ON DELETE CASCADE
);

CREATE TABLE de_userproperty
(
    id          bigint NOT NULL,
    concurrency integer DEFAULT 0,
    propertykey varchar(128) NOT NULL,
    propertyid  varchar(128) NOT NULL,

    CONSTRAINT de_property_pk PRIMARY KEY (id),
    CONSTRAINT de_property_uq UNIQUE (propertykey, propertyid)
);

CREATE TABLE de_userpropertyvalue
(
    property    bigint NOT NULL,
    name        varchar(128) NOT NULL,
    value       varchar(2000) NULL,

    CONSTRAINT de_propvalue_pk PRIMARY KEY (property, name),
    CONSTRAINT de_property_fk FOREIGN KEY (property) REFERENCES de_userproperty(id) ON DELETE CASCADE
);

CREATE TABLE de_sequences
(
    sequence_id     bigint NOT NULL,
    description     varchar(2000) NOT NULL,
    value           bigint NOT NULL,
    CONSTRAINT de_sequences_pk PRIMARY KEY (sequence_id)
);

-- note: do not uniquely constrain queryhash and modelversion, as the queryhash is not necessarily unique for
-- a given query
CREATE TABLE de_query
(
    id              bigint NOT NULL,
    guid            varchar(36) NOT NULL,
    query           varchar(2000) NOT NULL,
    queryhash       char(128) NOT NULL,
    majorversion    integer NOT NULL,
    modelvalid		bigint NOT NULL,
    updated			timestamp with time zone NOT NULL,
    delete_updated	timestamp with time zone DEFAULT CLOCK_TIMESTAMP() NOT NULL,

    CONSTRAINT de_query_pk PRIMARY KEY (id),
    CONSTRAINT de_query_guid_uq UNIQUE (guid),
    CONSTRAINT de_query_uq UNIQUE (queryhash, majorversion)
);

CREATE INDEX de_query_updated ON de_query (updated);
CREATE INDEX de_query_delete_updated ON de_query (delete_updated);


-- records the relationship between a resource and a resource query
CREATE TABLE de_queryheld
(
    resource_id     bigint NOT NULL,
    query_id        bigint NOT NULL,
    majorversion    integer NOT NULL,

    CONSTRAINT de_queryheld_pk PRIMARY KEY (resource_id, query_id),
    CONSTRAINT de_queryheld1_fk FOREIGN KEY (resource_id) REFERENCES de_resource(id) ON DELETE CASCADE,
    CONSTRAINT de_queryheld2_fk FOREIGN KEY (query_id) REFERENCES de_query(id) ON DELETE CASCADE
);

-- records the timestamp of when an organisation or resource change is made
CREATE TABLE de_querytimestamp
(
    tstype          integer NOT NULL,
    majorversion    integer NOT NULL,
    updated         timestamp with time zone NOT NULL,
    
    CONSTRAINT de_querytimestamp_pk PRIMARY KEY (tstype, majorversion)
);

INSERT INTO de_entitytype(id, name) VALUES(1, 'Organization');
INSERT INTO de_entitytype(id, name) VALUES(2, 'Organizational Unit');
INSERT INTO de_entitytype(id, name) VALUES(3, 'Group');
INSERT INTO de_entitytype(id, name) VALUES(4, 'Position');
INSERT INTO de_entitytype(id, name) VALUES(5, 'Privilege');
INSERT INTO de_entitytype(id, name) VALUES(6, 'Capability');
INSERT INTO de_entitytype(id, name) VALUES(7, 'Resource');
INSERT INTO de_entitytype(id, name) VALUES(8, 'Location');
INSERT INTO de_entitytype(id, name) VALUES(9, 'Organization Type');
INSERT INTO de_entitytype(id, name) VALUES(10, 'Organizational Unit Type');
INSERT INTO de_entitytype(id, name) VALUES(11, 'Position Type');
INSERT INTO de_entitytype(id, name) VALUES(12, 'Location Type');
INSERT INTO de_entitytype(id, name) VALUES(14, 'Position Held');
INSERT INTO de_entitytype(id, name) VALUES(16, 'Org-Unit Feature');
INSERT INTO de_entitytype(id, name) VALUES(17, 'Position Feature');
INSERT INTO de_entitytype(id, name) VALUES(18, 'Parameter Descriptor');
INSERT INTO de_entitytype(id, name) VALUES(19, 'Attribute');
INSERT INTO de_entitytype(id, name) VALUES(20, 'Resource Attribute');
INSERT INTO de_entitytype(id, name) VALUES(21, 'Qualifier');
INSERT INTO de_entitytype(id, name) VALUES(26, 'Extension Point');
INSERT INTO de_entitytype(id, name) VALUES(27, 'Model Org-Unit');
INSERT INTO de_entitytype(id, name) VALUES(28, 'Model Position');
INSERT INTO de_entitytype(id, name) VALUES(29, 'Query');

INSERT INTO de_sequences (sequence_id, description, value) VALUES (1, 'namedentity', 10);
INSERT INTO de_sequences (sequence_id, description, value) VALUES (2, 'userproperty', 10);
INSERT INTO de_sequences (sequence_id, description, value) VALUES (4, 'ldapcontainer', 10);
INSERT INTO de_sequences (sequence_id, description, value) VALUES (6, 'ldapcontainerresource', 10);
INSERT INTO de_sequences (sequence_id, description, value) VALUES (10, 'pushdestinations', 10);
INSERT INTO de_sequences (sequence_id, description, value) VALUES (11, 'extensionpoint', 10);
INSERT INTO de_sequences (sequence_id, description, value) VALUES (12, 'query', 10);

INSERT INTO de_resource values (1, 0, 'H', 'tibco-admin', 'tibco-admin', 'tibco-admin', null, null, 'system', 'UID=admin, OU=system', -1570783632, null, null, null, null, null, null, 0, 0, null, null, null, CURRENT_TIMESTAMP);
INSERT INTO de_groupheld values (1, 'CD4888DFE350794FE9185524F409A6F0');
INSERT INTO de_groupheld values (1, 'Undelivered');
INSERT INTO de_groupheld values (1, 'CF8999291E375FA9B249009F98C457A8');
INSERT INTO de_groupheld values (1, 'BBC750FBBDD594EDD04E42CAC1C731E7');
INSERT INTO de_groupheld values (1, 'CF931D25A207BF4C4458FF923692F350');

INSERT INTO de_deployedartefact values (0, 0, 1, 0, null, 'System Org Model', current_timestamp, null, current_timestamp, 'Create Script', true, 0, 1,
'<?xml version="1.0"?>
<directory
        xmlns="http://tibco.com/n2/directory-model/1.0"
        xmlns:demeta="http://tibco.com/n2/directory-metamodel/1.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://tibco.com/n2/directory-model/1.0 directory-model-1.0.xsd"
        name="sys_org_model">

    <privilege id="C1A9431AD2AECEA615D93FDAE7679F9A" name="All System Actions"/>
    <privilege id="D72C61ECF69CB7B58C52CC2B217FE9CE" name="BaseUser"/>
    <privilege id="C945A0764328A6670D264E23992BD9FF" name="LdapContainerManager"/>
    <privilege id="B96E20E1790FE3B7D1815825C80D362A" name="ResourceManager"/>

    <group id="Undelivered" name="Undelivered" isUndelivered="true"/>

    <group id="BBC750FBBDD594EDD04E42CAC1C731E7" name="System Administrator">
        <groupPrivilege privilegeId="C1A9431AD2AECEA615D93FDAE7679F9A"/>
    </group>

    <group id="CF8999291E375FA9B249009F98C457A8" name="Base User Profile">
        <groupPrivilege privilegeId="D72C61ECF69CB7B58C52CC2B217FE9CE"/>
    </group>

    <group id="CF931D25A207BF4C4458FF923692F350" name="LDAP Container Managers">
        <groupPrivilege privilegeId="C945A0764328A6670D264E23992BD9FF"/>
    </group>

    <group id="CD4888DFE350794FE9185524F409A6F0" name="Resource Managers">
        <groupPrivilege privilegeId="B96E20E1790FE3B7D1815825C80D362A"/>
    </group>

    <resource id="tibco-admin" resourceType="human" ldapalias="system" ldapdn="uid=admin,ou=system" name="tibco-admin">
        <resourceGroup groupId="Undelivered"/>
        <resourceGroup groupId="BBC750FBBDD594EDD04E42CAC1C731E7"/>
        <resourceGroup groupId="CF8999291E375FA9B249009F98C457A8"/>
        <resourceGroup groupId="CF931D25A207BF4C4458FF923692F350"/>
        <resourceGroup groupId="CD4888DFE350794FE9185524F409A6F0"/>
    </resource>
</directory>'
);






------------------------------------------------------------
-- Create ScriptEngine contribution  schema
------------------------------------------------------------





------------------------------------------------------------
-- Create ClientApps contribution  schema
------------------------------------------------------------



DROP TABLE IF EXISTS as_key_store_provider      CASCADE;
DROP TABLE IF EXISTS as_ssl_client_provider     CASCADE;
DROP TABLE IF EXISTS as_http_client             CASCADE;
-- Creates ACE Admin Service tables.

/*
 * A configuration that defines a KeyStoreProvider.
 *
 * Columns:
 *
 * id                   - The unique identifier for this SslClientProvider.
 * name                 - The name of the SslClientProvider.
 * description          - A description for the SslClientProvider.
 * key_store            - The data that is loaded into the KeyStore. The content of this binary data is BASE64 encoded.
 * key_store_type       - The type of the KeyStore. For example 'JCEKS', 'JKS', or 'PKCS12'.
 * password             - A password used to unlock the KeyStore.
 * security_provider    - The name of a KeyStore Security Provider.  For example 'SunJSSE'.  If not set the JVM default will be used.
 * modified_date        - The date-time (UTC) when this SslClientProvider was last modified.
 * encrypted            - Set true if the password is encrypted, false otherwise.
 *
 * Constraints:
 *
 * as_key_store_provider_pkey                  - PRIMARY KEY on id.
 * as_key_store_provider_unique_name_idx       - Case insensitive UNIQUE index on name.
 *
 * Sequence:
 *
 * as_key_store_provider_id_seq    - INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1
 */
CREATE TABLE IF NOT EXISTS as_key_store_provider
(
    id                  SERIAL PRIMARY KEY,
    name                VARCHAR(100) NOT NULL,
    description         VARCHAR(1024) NULL,
    key_store           VARCHAR(10000000) NOT NULL,
    key_store_type      VARCHAR(100) NOT NULL,
    password            VARCHAR(1024) NULL,
    security_provider   VARCHAR(100) NULL,
    modified_date       timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    encrypted           BOOLEAN NOT NULL
);

/*
 * A configuration that defines an SslClientProvider.
 *
 * Columns:
 *
 * id                               - The unique identifier for this SslClientProvider.
 * name                             - The name of the SslClientProvider.
 * description                      - A description for the SslClientProvider.
 * trust_store_provider_name        - The name of the KeyStoreProvider to use as the Trust Store.
 * enable_mutual_authentication     - Set true to enable Mutual Authentication.
 * identity_store_provider_name     - The name of the KeyStoreProvider containing the identity used for Mutual Authentication.  Required if enable_mutual_authentication is true.
 * key_alias_for_identity           - The alias name for the identity used for Mutual Authentication.
 * key_alias_password               - The password for the identity used for Mutual Authentication.
 * security_provider                - The name of an SSL Security Provider.  For example 'SunJSSE'.  If not set the JVM default will be used.
 * ssl_protocol                     - The SSL Protocol used.
 *                                      One of: SSL_V3, TLS_V1, TLS_V1_1, TLS_V1_2
 * ssl_cipher_class                 - The SSL Class used.
 *                                      One of: ALL_CIPHERS, AT_LEAST_128_BITS, AT_LEAST_256_BITS, EXPLICIT_CIPHERS, FIPS_CIPHERS, MORE_THAN_128_BITS, NO_EXPORTABLE_CIPHERS
 * explicit_cipher_list             - A list of explicitly named Ciphers.  This must be set if ssl_cipher_class is set to EXPLICIT_CIPHERS.
 * verify_remote_hostname           - Set true to verify the Host name.  This applies only when Mutual Authentication is enabled
 * expected_remote_hostname         - The expected Host name value to check.  Required if verify_remote_hostname is set true.
 * modified_date                    - The date-time (UTC) when this SslClientProvider was last modified.
 * encrypted                        - Set true if the key_alias_for_identity and key_alias_password are encrypted, false otherwise.
 *
 * Constraints:
 *
 * as_ssl_client_provider_pkey                                  - PRIMARY KEY on id.
 * as_ssl_client_provider_unique_name_idx                       - Case insensitive UNIQUE index on name.
 * as_ssl_client_provider_ssl_protocol_check                    - CHECK on ssl_protocol
 * as_ssl_client_provider_ssl_cipher_class_check                - CHECK on ssl_cipher_class
 * as_ssl_client_provider_trust_store_provider_id_fkey          - FOREIGN KEY on trust_store_provider_id
 * as_ssl_client_provider_identity_store_provider_id_fkey       - FOREIGN KEY on identity_store_provider_id
 * as_ssl_client_provider_enable_mutual_authentication_check    - CHECK: If enable_mutual_authentication is true then identity_store_provider_id and key_alias_for_identity are required.
 * as_ssl_client_provider_ssl_cipher_explicit_check             - CHECK: If ssl_cipher_class is set to 'EXPLICIT_CIPHERS' then explicit_cipher_list is required.
 *
 * Sequence:
 *
 * as_ssl_client_provider_id_seq    - INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1
 */
CREATE TABLE IF NOT EXISTS as_ssl_client_provider
(
    id                              SERIAL PRIMARY KEY,
    name                            VARCHAR(100) NOT NULL,
    description                     VARCHAR(1024) NULL,
    trust_store_provider_id         INTEGER NOT NULL REFERENCES as_key_store_provider(id) ON DELETE RESTRICT,
    enable_mutual_authentication    BOOLEAN DEFAULT false NOT NULL,
    identity_store_provider_id      INTEGER NULL REFERENCES as_key_store_provider(id) ON DELETE RESTRICT,
    key_alias_for_identity          VARCHAR(1024) NULL,
    key_alias_password              VARCHAR(1024) NULL,
    security_provider               VARCHAR(100) NULL,
    ssl_protocol                    VARCHAR(8) DEFAULT 'TLS_V1_2' NOT NULL CHECK(
                                        ssl_protocol = 'SSL_V3'
                                        OR ssl_protocol = 'TLS_V1'
                                        OR ssl_protocol = 'TLS_V1_1'
                                        OR ssl_protocol = 'TLS_V1_2'),
    ssl_cipher_class                VARCHAR(21) DEFAULT 'AT_LEAST_256_BITS' NOT NULL CHECK(
                                        ssl_cipher_class = 'ALL_CIPHERS'
                                        OR ssl_cipher_class = 'AT_LEAST_128_BITS'
                                        OR ssl_cipher_class = 'AT_LEAST_256_BITS'
                                        OR ssl_cipher_class = 'EXPLICIT_CIPHERS'
                                        OR ssl_cipher_class = 'FIPS_CIPHERS'
                                        OR ssl_cipher_class = 'MORE_THAN_128_BITS'
                                        OR ssl_cipher_class = 'NO_EXPORTABLE_CIPHERS'),
    explicit_cipher_list            VARCHAR(8192) NULL,
    verify_remote_hostname          BOOLEAN DEFAULT false NOT NULL,
    expected_remote_hostname        VARCHAR(256) NULL,
    modified_date                   timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    encrypted                       BOOLEAN NOT NULL,
    CONSTRAINT as_ssl_client_provider_enable_mutual_authentication_check CHECK (
        enable_mutual_authentication = false OR
        (identity_store_provider_id IS NOT NULL AND key_alias_for_identity IS NOT NULL)),
    CONSTRAINT as_ssl_client_provider_ssl_cipher_explicit_check CHECK (
        ssl_cipher_class != 'EXPLICIT_CIPHERS' OR explicit_cipher_list IS NOT NULL)
);

/*
 * A configuration that defines an HttpClient.
 *
 * Columns:
 *
 * id                       - The unique identifier for this HttpClient.
 * name                     - The name of the HttpClient.
 * description              - A description for the HttpClient.
 * machine_name             - The name of the host that accepts the incoming requests.
 * port                     - The port number on which to invoke outgoing HTTP requests.
 * socket_timeout           - The timeout in milliseconds waiting for data or a maximum period inactivity between consecutive data packets, default=0.
 * connection_timeout       - The timeout in milliseconds until a connection is established.
 * accept_redirect          - Indicates whether the HTTP method should automatically follow HTTP redirects, default=false.
 * reuse_address            - Controls reuse of a socket address, default=false.
 * suppress_tcp_delay       - Determines whether the Nagle algorithm is used, default: true
 * stale_check_validation   - A time value in milliseconds that determines how a stale connection check is applied, default=-1.
 * time_to_live             - The maximum time in milliseconds that a connection remains available for use, default=-1.
 * buffer_size              - Socket buffer size in bytes, default=-1
 * local_socket_address     - Local host address to be used for creating the socket.
 * configure_proxy          - Set true to configure the HTTP Proxy options, default=false.
 * proxy_type               - Type of proxy server, HTTP or SOCKS V4 / V5.  Required if configure_proxy set true.
 * proxy_host               - Address of the proxy host.  Required if configure_proxy set true.
 * proxy_port               - Port of the proxy host.  Required if configure_proxy set true.
 * conf_basic_auth          - Set true to configure access to proxy server with a username and password, default=false.
 * username                 - The username used for the proxy server BASIC authentication.  Required if conf_basic_auth is set true.
 * password                 - The password used for the proxy server BASIC authentication.  Applies only if conf_basic_auth is set true.
 * enable_ssl               - Set true to enable SSL, default=false.
 * ssl_client_provider_id   - The id that references the as_ssl_client_provider table.  Required if enable_ssl set true.
 * modified_date            - The date-time (UTC) when this HttpClient was last modified.
 * reference_count          - This is used to determine current references to this HttpClient.
 * encrypted                - Set true if the username and password are encrypted, false otherwise.
 *
 * Constraints:
 *
 * as_http_client_pkey                          - PRIMARY KEY on id.
 * as_http_client_unique_name_idx               - Case insensitive UNIQUE index on name.
 * as_http_client_proxy_type_check              - CHECK on proxy_type.
 * as_http_client_ssl_client_provider_id_fkey   - FOREIGN KEY on ssl_client_provider_id
 * as_http_client_configure_proxy_check         - CHECK: If configure_proxy is true then proxy_type, proxy_host, proxy_port are required.
 * as_http_client_conf_basic_auth_check         - CHECK: If conf_basic_auth is true then username is required.
 * as_http_client_enable_ssl_check              - CHECK: If enable_ssl is true then ssl_client_provider_id is required.
 *
 * Sequence:
 *
 * as_http_client_id_seq            - INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1
 */
CREATE TABLE IF NOT EXISTS as_http_client
(
    id                      SERIAL PRIMARY KEY,
    name                    VARCHAR(100) NOT NULL,
    description             VARCHAR(1024) NULL,
    machine_name            VARCHAR(256) NOT NULL,
    port                    INTEGER NOT NULL,
    socket_timeout          INTEGER DEFAULT 0 NOT NULL,
    connection_timeout      INTEGER DEFAULT 0 NOT NULL,
    accept_redirect         BOOLEAN DEFAULT false NOT NULL,
    reuse_address           BOOLEAN DEFAULT false NOT NULL,
    suppress_tcp_delay      BOOLEAN DEFAULT true NOT NULL,
    stale_check_validation  INTEGER DEFAULT -1 NOT NULL,
    time_to_live            INTEGER DEFAULT -1 NOT NULL,
    buffer_size             INTEGER DEFAULT -1 NOT NULL,
    local_socket_address    VARCHAR(256) NULL,
    configure_proxy         BOOLEAN DEFAULT false NOT NULL,
    proxy_type              VARCHAR(11) NULL CHECK(
                                proxy_type = 'HTTP'
                                OR proxy_type = 'SOCKS_V4_V5'
                                OR proxy_type IS NULL),
    proxy_host              VARCHAR(256) NULL,
    proxy_port              INTEGER NULL,
    conf_basic_auth         BOOLEAN DEFAULT false NOT NULL,
    username                VARCHAR(1024) NULL,
    password                VARCHAR(1024) NULL,
    enable_ssl              BOOLEAN DEFAULT false NOT NULL,
    ssl_client_provider_id  INTEGER NULL REFERENCES as_ssl_client_provider(id) ON DELETE RESTRICT,
    modified_date           timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reference_count         INTEGER DEFAULT 0 NOT NULL,
    encrypted               BOOLEAN NOT NULL,
    CONSTRAINT as_http_client_configure_proxy_check CHECK (
        configure_proxy = false OR
        (proxy_type IS NOT NULL AND proxy_host IS NOT NULL AND proxy_port IS NOT NULL)),
    CONSTRAINT as_http_client_conf_basic_auth_check CHECK (
        conf_basic_auth = false OR username IS NOT NULL),
    CONSTRAINT as_http_client_enable_ssl_check CHECK (
        enable_ssl = false OR ssl_client_provider_id IS NOT NULL)
);

CREATE UNIQUE INDEX as_key_store_provider_unique_name_idx on as_key_store_provider (LOWER(name));
CREATE UNIQUE INDEX as_ssl_client_provider_unique_name_idx on as_ssl_client_provider (LOWER(name));
CREATE UNIQUE INDEX as_http_client_unique_name_idx on as_http_client (LOWER(name));


