using System.Collections;
using System.Collections.Generic;
using Microsoft.Build.Framework;

namespace RichardSzalay.Helix.Publishing.Tasks.Tests
{
    public class FakeTaskItem : ITaskItem, IEnumerable<KeyValuePair<string, string>>
    {
        private readonly Dictionary<string, string> metadata = new Dictionary<string, string>();

        public FakeTaskItem(string itemSpec)
        {
            this.ItemSpec = itemSpec;
        }

        // For object initializer
        public void Add(string metadataName, string metadataValue)
        {
            SetMetadata(metadataName, metadataValue);
        }

        public string ItemSpec { get; set; }

        public ICollection MetadataNames => metadata.Keys;

        public int MetadataCount => metadata.Count;

        public IDictionary CloneCustomMetadata()
        {
            return new Dictionary<string, string>(metadata);
        }

        public void CopyMetadataTo(ITaskItem destinationItem)
        {
            throw new System.NotImplementedException();
        }

        public string GetMetadata(string metadataName)
        {
            if (metadata.TryGetValue(metadataName, out string value))
            {
                return value;
            }

            return string.Empty;
        }

        public void RemoveMetadata(string metadataName)
        {
            metadata.Remove(metadataName);
        }

        public void SetMetadata(string metadataName, string metadataValue)
        {
            metadata[metadataName] = metadataValue;
        }

        public IEnumerator<KeyValuePair<string, string>> GetEnumerator()
        {
            throw new System.NotImplementedException();
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return metadata.GetEnumerator();
        }
    }

}
