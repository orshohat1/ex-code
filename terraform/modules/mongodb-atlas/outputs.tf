output "cluster_id" {
  description = "The ID of the MongoDB Atlas cluster"
  value       = mongodbatlas_cluster.cluster.id
}
