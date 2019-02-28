using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.Text.RegularExpressions;

namespace RichardSzalay.Helix.Publishing.Tasks
{
    public class MatchAdditionalItemMetadata : Task
    {
        [Required]
        public ITaskItem[] Items { get; set; }

        [Required]
        public string Pattern { get; set; }

        public string SourceMetadataName { get; set; } = "Name";

        [Output]
        public ITaskItem[] Output { get; set; }

        public override bool Execute()
        {
            if (Items == null || Items.Length == 0)
            {
                Log.LogError("No items were supplied");
                return false;
            }

            try
            {
                var regex = new Regex(Pattern);
                var groupNames = regex.GetGroupNames();

                foreach (var item in Items)
                {
                    var sourceMetadata = item.GetMetadata(SourceMetadataName);

                    if (string.IsNullOrEmpty(sourceMetadata))
                    {
                        continue;
                    }

                    var match = regex.Match(sourceMetadata);

                    if (!match.Success)
                    {
                        this.Log.LogWarning($"Pattern did not match");
                    }

                    for (var i = 1; i< groupNames.Length; i++)
                    {
                        var groupName = groupNames[i];

                        var group = match.Groups[groupName];

                        if (group != null && group.Success)
                        {
                            item.SetMetadata(groupName, group.Value);
                        }
                    }
                }

                Output = Items;

                return true;
            }
            catch (Exception ex)
            {
                Log.LogErrorFromException(ex);
                return false;
            }
        }
    }
}
