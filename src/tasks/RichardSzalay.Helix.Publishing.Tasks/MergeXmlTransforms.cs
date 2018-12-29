using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.IO;
using System.Linq;
using System.Xml;

namespace RichardSzalay.Helix.Publishing.Tasks
{
    public class MergeXmlTransforms : Task
    {
        [Required]
        public ITaskItem Target { get; set; }

        [Required]
        public ITaskItem[] Transforms { get; set; }

        [Required]
        public string OutputPath { get; set; }

        [Output]
        public ITaskItem Output { get; set; }

        public override bool Execute()
        {
            if (Transforms == null)
            {
                Log.LogError("No transforms were supplied");
                return false;
            }

            try
            {
                var transformXml = Transforms.Select(item => ParseXmlDocument(item.ItemSpec));

                var rootElement = ParseXmlDocument(Target.ItemSpec).DocumentElement.LocalName;

                var mergedTransforms = XmlTransformMerger.Merge(rootElement, transformXml);

                EnsureDirectoryExists(Path.GetDirectoryName(OutputPath));

                mergedTransforms.Save(OutputPath);

                return true;
            }
            catch (Exception ex)
            {
                Log.LogErrorFromException(ex);
                return false;
            }
        }

        private void EnsureDirectoryExists(string path)
        {
            if (!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }
        }

        static XmlDocument ParseXmlDocument(string xml)
        {
            var doc = new XmlDocument();
            doc.Load(xml);
            return doc;
        }
    }
}
