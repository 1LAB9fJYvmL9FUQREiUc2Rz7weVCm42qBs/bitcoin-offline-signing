#!/bin/bash
# convert a transaction XML file
# Note: Due to the fact that qrencode cannot handle input streams >4k, the following measures are taken to minimize the data:
# - @desc attributes of the XML file will be stripped
# - the data will be gzipped and base64-encoded
mytheme=${1:-"dark"}
dirname=`dirname $0`


xmlstarlet tr \
	<(echo '<?xml version="1.0"?>
	<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
		<xsl:output omit-xml-declaration="yes" indent="yes"/>
		<xsl:template match="node()|@*" priority="1">
			<xsl:copy>
				<xsl:apply-templates select="node()|@*"/>
			</xsl:copy>
		</xsl:template>
		<xsl:template match="@desc" priority="2"/>
	</xsl:stylesheet>') \
| gzip \
| base64 --wrap=0 \
#| $dirname/qrascii.sh ${mytheme} \


