using System.Collections.Generic;
using System.Linq;
using System.Xml;

namespace RichardSzalay.Helix.Publishing.Tasks
{
    public class XmlTransformMerger
    {
        public static XmlDocument Merge(string rootElement, IEnumerable<XmlDocument> transforms)
        {
            return transforms
                .Aggregate(CreateEmptyXmlTransform(rootElement), MergeXmlDocument);
        }

        static XmlDocument MergeXmlDocument(XmlDocument target, XmlDocument source)
        {
            var targetElement = target.DocumentElement;
            var elements = source.DocumentElement.ChildNodes;

            foreach (XmlNode element in elements)
            {
                ImportChild(targetElement, element);
            }

            return target;
        }

        static void ImportChild(XmlElement target, XmlNode node)
        {
            var importedNode = target.OwnerDocument.ImportNode(node, true);

            target.AppendChild(importedNode);
        }

        static XmlDocument ParseXmlDocument(string xml)
        {
            var doc = new XmlDocument();
            doc.Load(xml);
            return doc;
        }

        static XmlDocument CreateEmptyXmlTransform(string rootElementName)
        {
            var doc = new XmlDocument();

            var nsm = new XmlNamespaceManager(doc.NameTable);
            nsm.AddNamespace("xdt", "http://schemas.microsoft.com/XML-Document-Transform");

            doc.AppendChild(doc.CreateElement(rootElementName));

            return doc;
        }
    }
}
