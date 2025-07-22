{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {
            "x": 0,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true,
                "value": "workspace"
              },
              {
                "name": "ComponentId",
                "isOptional": true,
                "value": {
                  "SubscriptionId": "${subscription_id}",
                  "ResourceGroup": "${resource_group_name}",
                  "Name": "${aks_cluster_name}",
                  "ResourceId": "/subscriptions/${subscription_id}/resourcegroups/${resource_group_name}/providers/Microsoft.ContainerService/managedClusters/${aks_cluster_name}"
                }
              },
              {
                "name": "Scope",
                "isOptional": true,
                "value": {
                  "ResourceIds": [
                    "/subscriptions/${subscription_id}/resourcegroups/${resource_group_name}/providers/Microsoft.ContainerService/managedClusters/${aks_cluster_name}"
                  ]
                }
              },
              {
                "name": "PartId",
                "isOptional": true,
                "value": "Kubelet CPU Usage"
              },
              {
                "name": "Version",
                "isOptional": true,
                "value": "1.0"
              },
              {
                "name": "TimeRange",
                "isOptional": true,
                "value": "P1D"
              },
              {
                "name": "DashboardId",
                "isOptional": true,
                "value": "/subscriptions/${subscription_id}/resourcegroups/${resource_group_name}/providers/Microsoft.Portal/dashboards/aks-monitoring-dashboard"
              },
              {
                "name": "DraftRequestParameters",
                "isOptional": true,
                "value": {
                  "scope": "hierarchy"
                }
              },
              {
                "name": "Query",
                "isOptional": true,
                "value": "let endDateTime = now();\nlet startDateTime = ago(1h);\nlet trendBinSize = 1m;\nlet capacityCounterName = 'cpuCapacityNanoCores';\nlet usageCounterName = 'cpuUsageNanoCores';\nlet clusterName = '${aks_cluster_name}';\nKubePodInventory\n| where TimeGenerated < endDateTime\n| where TimeGenerated >= startDateTime\n| where ClusterName == clusterName\n| extend InstanceName = strcat(ClusterId, '/', ContainerName),\n         ContainerName = strcat(ControllerName, '/', tostring(split(ContainerName, '/')[1]))\n| distinct Computer, InstanceName, ContainerName\n| join hint.strategy=shuffle (\n    Perf\n    | where TimeGenerated < endDateTime\n    | where TimeGenerated >= startDateTime\n    | where ObjectName == 'K8SContainer'\n    | where CounterName == capacityCounterName\n    | summarize LimitValue = max(CounterValue) by Computer, InstanceName, bin(TimeGenerated, trendBinSize)\n    | project Computer, InstanceName, LimitStartTime = TimeGenerated, LimitEndTime = TimeGenerated + trendBinSize, LimitValue\n) on Computer, InstanceName\n| join kind=inner hint.strategy=shuffle (\n    Perf\n    | where TimeGenerated < endDateTime\n    | where TimeGenerated >= startDateTime\n    | where ObjectName == 'K8SContainer'\n    | where CounterName == usageCounterName\n    | project Computer, InstanceName, UsageValue = CounterValue, TimeGenerated\n) on Computer, InstanceName\n| where TimeGenerated >= LimitStartTime and TimeGenerated < LimitEndTime\n| project Computer, ContainerName, TimeGenerated, UsagePercent = UsageValue * 100.0 / LimitValue\n| summarize AggregatedValue = avg(UsagePercent) by bin(TimeGenerated, trendBinSize), ContainerName\n| render timechart"
              },
              {
                "name": "ControlType",
                "isOptional": true,
                "value": "FrameControlChart"
              },
              {
                "name": "SpecificChart",
                "isOptional": true,
                "value": "Line"
              },
              {
                "name": "PartTitle",
                "isOptional": true,
                "value": "CPU Usage by Container"
              },
              {
                "name": "PartSubTitle",
                "isOptional": true,
                "value": "${aks_cluster_name}"
              },
              {
                "name": "Dimensions",
                "isOptional": true,
                "value": {
                  "xAxis": {
                    "name": "TimeGenerated",
                    "type": "datetime"
                  },
                  "yAxis": [
                    {
                      "name": "AggregatedValue",
                      "type": "real"
                    }
                  ],
                  "splitBy": [
                    {
                      "name": "ContainerName",
                      "type": "string"
                    }
                  ],
                  "aggregation": "Sum"
                }
              },
              {
                "name": "LegendOptions",
                "isOptional": true,
                "value": {
                  "isEnabled": true,
                  "position": "Bottom"
                }
              },
              {
                "name": "IsQueryContainTimeRange",
                "isOptional": true,
                "value": false
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {
              "content": {
                "PartTitle": "CPU Usage by Container",
                "PartSubTitle": "${aks_cluster_name}"
              }
            }
          }
        },
        "1": {
          "position": {
            "x": 6,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true,
                "value": "workspace"
              },
              {
                "name": "ComponentId",
                "isOptional": true,
                "value": {
                  "SubscriptionId": "${subscription_id}",
                  "ResourceGroup": "${resource_group_name}",
                  "Name": "${aks_cluster_name}",
                  "ResourceId": "/subscriptions/${subscription_id}/resourcegroups/${resource_group_name}/providers/Microsoft.ContainerService/managedClusters/${aks_cluster_name}"
                }
              },
              {
                "name": "Scope",
                "isOptional": true,
                "value": {
                  "ResourceIds": [
                    "/subscriptions/${subscription_id}/resourcegroups/${resource_group_name}/providers/Microsoft.ContainerService/managedClusters/${aks_cluster_name}"
                  ]
                }
              },
              {
                "name": "PartId",
                "isOptional": true,
                "value": "Kubelet Memory Usage"
              },
              {
                "name": "Version",
                "isOptional": true,
                "value": "1.0"
              },
              {
                "name": "TimeRange",
                "isOptional": true,
                "value": "P1D"
              },
              {
                "name": "DashboardId",
                "isOptional": true,
                "value": "/subscriptions/${subscription_id}/resourcegroups/${resource_group_name}/providers/Microsoft.Portal/dashboards/aks-monitoring-dashboard"
              },
              {
                "name": "DraftRequestParameters",
                "isOptional": true,
                "value": {
                  "scope": "hierarchy"
                }
              },
              {
                "name": "Query",
                "isOptional": true,
                "value": "let endDateTime = now();\nlet startDateTime = ago(1h);\nlet trendBinSize = 1m;\nlet capacityCounterName = 'memoryCapacityBytes';\nlet usageCounterName = 'memoryRssBytes';\nlet clusterName = '${aks_cluster_name}';\nKubePodInventory\n| where TimeGenerated < endDateTime\n| where TimeGenerated >= startDateTime\n| where ClusterName == clusterName\n| extend InstanceName = strcat(ClusterId, '/', ContainerName),\n         ContainerName = strcat(ControllerName, '/', tostring(split(ContainerName, '/')[1]))\n| distinct Computer, InstanceName, ContainerName\n| join hint.strategy=shuffle (\n    Perf\n    | where TimeGenerated < endDateTime\n    | where TimeGenerated >= startDateTime\n    | where ObjectName == 'K8SContainer'\n    | where CounterName == capacityCounterName\n    | summarize LimitValue = max(CounterValue) by Computer, InstanceName, bin(TimeGenerated, trendBinSize)\n    | project Computer, InstanceName, LimitStartTime = TimeGenerated, LimitEndTime = TimeGenerated + trendBinSize, LimitValue\n) on Computer, InstanceName\n| join kind=inner hint.strategy=shuffle (\n    Perf\n    | where TimeGenerated < endDateTime\n    | where TimeGenerated >= startDateTime\n    | where ObjectName == 'K8SContainer'\n    | where CounterName == usageCounterName\n    | project Computer, InstanceName, UsageValue = CounterValue, TimeGenerated\n) on Computer, InstanceName\n| where TimeGenerated >= LimitStartTime and TimeGenerated < LimitEndTime\n| project Computer, ContainerName, TimeGenerated, UsagePercent = UsageValue * 100.0 / LimitValue\n| summarize AggregatedValue = avg(UsagePercent) by bin(TimeGenerated, trendBinSize), ContainerName\n| render timechart"
              },
              {
                "name": "ControlType",
                "isOptional": true,
                "value": "FrameControlChart"
              },
              {
                "name": "SpecificChart",
                "isOptional": true,
                "value": "Line"
              },
              {
                "name": "PartTitle",
                "isOptional": true,
                "value": "Memory Usage by Container"
              },
              {
                "name": "PartSubTitle",
                "isOptional": true,
                "value": "${aks_cluster_name}"
              },
              {
                "name": "Dimensions",
                "isOptional": true,
                "value": {
                  "xAxis": {
                    "name": "TimeGenerated",
                    "type": "datetime"
                  },
                  "yAxis": [
                    {
                      "name": "AggregatedValue",
                      "type": "real"
                    }
                  ],
                  "splitBy": [
                    {
                      "name": "ContainerName",
                      "type": "string"
                    }
                  ],
                  "aggregation": "Sum"
                }
              },
              {
                "name": "LegendOptions",
                "isOptional": true,
                "value": {
                  "isEnabled": true,
                  "position": "Bottom"
                }
              },
              {
                "name": "IsQueryContainTimeRange",
                "isOptional": true,
                "value": false
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {
              "content": {
                "PartTitle": "CPU Usage by Container",
                "PartSubTitle": "${aks_cluster_name}"
              }
            }
          }
        }
      }
    }
  }
} 