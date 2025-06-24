String _stringFromJson(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) {
    return value;
  }
  if (value == null) {
    return '';
  }
  return value.toString();
}

class StructuredPlantingGuide {
  final String seedName;
  final String region;
  final Timeline timeline;
  final List<PrePlantingTask> prePlantingTasks;
  final List<PlantingTask> plantingTasks;
  final List<PostPlantingTask> postPlantingTasks;
  final String summary;

  StructuredPlantingGuide({
    required this.seedName,
    required this.region,
    required this.timeline,
    required this.prePlantingTasks,
    required this.plantingTasks,
    required this.postPlantingTasks,
    required this.summary,
  });

  factory StructuredPlantingGuide.fromJson(Map<String, dynamic> json) {
    return StructuredPlantingGuide(
      seedName: _stringFromJson(json, 'seed_name'),
      region: _stringFromJson(json, 'region'),
      timeline: json['timeline'] is Map<String, dynamic>
          ? Timeline.fromJson(json['timeline'])
          : Timeline(duration: 'N/A', bestTimeToPlant: 'N/A'),
      prePlantingTasks: json['pre_planting_tasks'] is List
          ? List<PrePlantingTask>.from(json['pre_planting_tasks']
              .map((x) => PrePlantingTask.fromJson(x)))
          : [],
      plantingTasks: json['planting_tasks'] is List
          ? List<PlantingTask>.from(
              json['planting_tasks'].map((x) => PlantingTask.fromJson(x)))
          : [],
      postPlantingTasks: json['post_planting_tasks'] is List
          ? List<PostPlantingTask>.from(json['post_planting_tasks']
              .map((x) => PostPlantingTask.fromJson(x)))
          : [],
      summary: _stringFromJson(json, 'summary'),
    );
  }
}

class Timeline {
  final String duration;
  final String bestTimeToPlant;

  Timeline({required this.duration, required this.bestTimeToPlant});

  factory Timeline.fromJson(Map<String, dynamic> json) {
    return Timeline(
      duration: _stringFromJson(json, 'duration'),
      bestTimeToPlant: _stringFromJson(json, 'best_time_to_plant'),
    );
  }
}

class PrePlantingTask {
  final String task;
  final String description;

  PrePlantingTask({required this.task, required this.description});

  factory PrePlantingTask.fromJson(Map<String, dynamic> json) {
    return PrePlantingTask(
      task: _stringFromJson(json, 'task'),
      description: _stringFromJson(json, 'description'),
    );
  }
}

class PlantingTask {
  final String task;
  final String description;

  PlantingTask({required this.task, required this.description});

  factory PlantingTask.fromJson(Map<String, dynamic> json) {
    return PlantingTask(
      task: _stringFromJson(json, 'task'),
      description: _stringFromJson(json, 'description'),
    );
  }
}

class PostPlantingTask {
  final String task;
  final String description;

  PostPlantingTask({required this.task, required this.description});

  factory PostPlantingTask.fromJson(Map<String, dynamic> json) {
    return PostPlantingTask(
      task: _stringFromJson(json, 'task'),
      description: _stringFromJson(json, 'description'),
    );
  }
} 