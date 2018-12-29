using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System.Collections.Generic;
using System.Xml;

namespace RichardSzalay.Helix.Publishing.Tasks
{
    public class WriteItemsToFile : Task
    {
        [Required]
        public ITaskItem[] Items { get; set; }

        [Required]
        public string File { get; set; }

        public override bool Execute()
        {
            if (Items == null)
            {
                Log.LogError("No items were supplied");
                return false;
            }

            if (System.IO.File.Exists(File))
                System.IO.File.Delete(File);

            using (var writer = XmlTextWriter.Create(File))
            {
                writer.WriteStartElement("items");

                foreach (var item in Items)
                {
                    WriteItem(item, writer);
                }

                writer.WriteEndElement();

                writer.Flush();
            }

            return true;
        }

        private void WriteItem(ITaskItem item, XmlWriter writer)
        {
            writer.WriteStartElement("item");

            var usedKeys = new HashSet<string>();

            foreach (string key in item.MetadataNames)
            {
                if (usedKeys.Contains(key))
                    continue;

                usedKeys.Add(key);

                writer.WriteAttributeString(key, item.GetMetadata(key));
            }

            writer.WriteEndElement();
        }
    }
}
