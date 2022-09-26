local gateway = import 'loki/gateway.libsonnet';

local loki = import 'loki/loki.libsonnet';

local promtail = import 'promtail/promtail.libsonnet';

loki + promtail + gateway {
  _config+:: {
    compactor_pvc_size: "1Gi",
    index_gateway_pvc_size: "1Gi",
    ingester_pvc_size: "1Gi",
    querier_pvc_size: "1Gi",
    ruler_pvc_size: "1Gi",

    namespace: 'loki',
    htpasswd_contents: 'loki:$apr1$H4yGiGNg$ssl5/NymaGFRUvxIV1Nyr.',

    // S3 variables -- Remove if not using s3
    storage_backend: 's3',
    s3_access_key: 'WIEoUuuwlonePz5J',
    s3_secret_access_key: 'F17KaByzofy49PJ5tZ9NvIDwIjdVUI1R',
    s3_address: 'minio-dev.default.svc.cluster.local:9000',
    s3_bucket_name: 'loki-test',
    s3_path_style: true, // needed for minio
    // dynamodb_region: 'region',

    // GCS variables -- Remove if not using gcs
    // storage_backend: 'bigtable,gcs',
    // bigtable_instance: 'instance',
    // bigtable_project: 'project',
    // gcs_bucket_name: 'bucket',

    //Set this variable based on the type of object storage you're using.
    boltdb_shipper_shared_store: 's3',

    //Update the object_store and from fields
    loki+: {
      schema_config: {
        configs: [{
          from: '2022-01-01',
          store: 'boltdb-shipper',
          object_store: 's3',
          schema: 'v11',
          index: {
            prefix: '%s_index_' % $._config.table_prefix,
            period: '%dh' % $._config.index_period_hours,
          },
        }],
      },
    },

    //Update the container_root_path if necessary
    promtail_config+: {
      clients: [{
        scheme:: 'http',
        hostname:: 'gateway.%(namespace)s.svc' % $._config,
        username:: 'loki',
        password:: 'password',
        container_root_path:: '/var/lib/docker',
      }],
    },
    
    replication_factor: 3,
    consul_replicas: 1,
    memcached_replicas: 1,

    queryFrontend+: {
      replicas: 1
    }
  },

  // reset config for test env.
  local kk = import "github.com/jsonnet-libs/k8s-libsonnet/1.22/main.libsonnet",
  local one_replicas_of_deployment = kk.apps.v1.deployment.spec.withReplicas(1),
  gateway_deployment+: one_replicas_of_deployment,
  distributor_deployment+: one_replicas_of_deployment,

  local one_replicas_of_statefulset = kk.apps.v1.statefulSet.spec.withReplicas(1),
  ingester_statefulset+: one_replicas_of_statefulset,
  querier_statefulset+: one_replicas_of_statefulset,

  local k = import 'ksonnet-util/kausal.libsonnet',
  local pvc = k.core.v1.persistentVolumeClaim,
  ingester_wal_pvc+:pvc.mixin.spec.resources.withRequests({ storage: '5Gi' }),

  ingester_container+:: k.util.resourcesRequests('2', '1Gi'),
  distributor_container+:: k.util.resourcesRequests('1', '500Mi'),
  ruler_container+:: k.util.resourcesRequests('1', '1Gi'),
  query_frontend_container+:: k.util.resourcesRequests('2', '1Gi'),
  query_scheduler_container+:: k.util.resourcesRequests('1', '500Mi'),
  compactor_container+:: k.util.resourcesRequests('2', '1Gi'),
  querier_container+:: k.util.resourcesRequests('1', '500Mi'),

  memcached+: {
    cpu_requests: "1",
  }
}
