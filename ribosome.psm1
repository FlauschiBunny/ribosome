#
# Copyright (c) 2021 Till Fischer All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom
# the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#
[int] $prologueLine = 23
[string] $PROLOGUE = @"
#
# The initial part of this file belongs to the ribosome project.
#
# Copyright (c) 2021 Till Fischer All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom
# the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#
  
TODO Hier kommt der Prologue rein

"@



#classes for more readable code than just tuples
class DnaStackEntry {
    [Object[]]$dnaArgs
    [string]$dnaName
    [int]$lineNumber
    [string]$baseDir

    DnaStackEntry($dnaArgs,$dnaName,$lineNumber,$baseDir){
        $this.dnaArgs = $dnaArgs
        $this.dnaName = $dnaName
        $this.lineNumber = $lineNumber
        $this.baseDir = $baseDir
    }
}

#Keep track of global rna line numbers
class RnaLineMapEntry {
    [int] $rnaLineNumber
    [string] $dnaName
    [int] $danLineNumber

    RnaLineMapEntry($rnaLineNumber, $dnaName, $dnaLineNumber){
        $this.rnaLineNumber = $rnaLineNumber
        $this.dnaName = $dnaName
        $this.dnaLineNumber = $dnaLineNumber
    }
}

function Write-DnaError {
    param (
        [string]$message,
        [System.Collections.Stack]$dnaStack
    )
    Write-Error -Message "$($dnaStack.Peek().dnaName):$($dnaStack.Peek().lineNumber) - $message"
}

function Write-Rna{
    param (
        [string]$line, 
        [int]$rnaLineNumber, 
        [string]$rnaFile, 
        [RnaLineMapEntry[]]$lineMap, 
        [System.Collections.Stack]$dnaStack
    )
    $lineMap.Add([RnaLineMapEntry]::new($rnaLineNumber, $dnaStack.Peek().dnaName, $dnaStack.Peek().lineNumber))
    if ($rnaSwitch){
        Write-Host $line
    }else {
        Add-Content -Path $rnaFile -Value $line
    }
}
# Main function of this module
#TODO write help
function ribosome {
    [CmdletBinding()]
    param (
         # Name of the DNA-file to process, should end with .ps1.dna
        [Parameter(Mandatory=$true)][string]$Dna,
        # direcly outputs the RNA
        [Parameter()][switch]$Rna,
        # Object that holds the Arguments for the DNA, if an array is used, the dna is getting applied to every element, can be supported by pipeline
        [Parameter(ValueFromPipeline=$true, ValueFromRemainingArguments)]$DnaArgs
    )
    # prepares the rna file for repeated execution 
    begin {
        Write-Debug "begin-block"
        # Given that we can 'require' other DNA files, we need to keep a stack of
        # open DNA files. We also keep the name of the file and the line number to
        # be able to report errors. We'll also keep track of the directory the DNA file
        # is in to be able to correctly expand relative paths in /!include commands.
        $dnaStack = New-Object System.Collections.Stack
        $lineMap =@()
        $rnaLineNumber = 1
        $rnaFile = ""#TODO

        # initialize the rna file with the prologue
        $initialDnaStackEntry = [DnaStackEntry]::new($null, "ribosome.psm1", $prologueLine, $PSScriptRoot)
        $dnaStack.Push($initialDnaStackEntry)
        Write-Rna -line $PROLOGUE -rnaLineNumber $rnaLineNumber -rnaFile $rnaFile -lineMap $lineMap -dnaStack $dnaStack

        # read the dna file and push it in the stack
        $dnaLines = Get-Content -Path $Dna
        $dnaStack.push([DnaStackEntry]::new($dnaLines, $Dna, 0, $PSScriptRoot))

        # process dna file
        while ($true) {
            # get next line
            while ($true){
                # assign first element to $line, the others back to the stackentry
                $line, $dnaStack.Peek().DnaArgs = $dnaStack.Peek().DnaArgs
                # remove stack entry if no more lines in array
                if ($null -eq $line){
                    $dnaStack.Pop()
                }
                if ($dnaStack.Count -eq 1){
                    break
                }
            }
            # stop processing if no more line available
            if ($null -eq $line){
                break
            }
            # we are counting lines so we can report line numbers in errors
            $dnaStack.Peek().dnaLineNumber += 1


        }
    }
    # executes the rna file for each $DnaArgs object either from parameter or from the pipeline
    process {
        foreach ($object in $DnaArgs) {
            Write-Debug "process-block: $object" 
            Invoke-Expression $rnaFile $object -ErrorAction Continue
        }
    }    
    # clean up
    end {
        Write-Debug "end-block"
        Remove-Item $rnaFile
    }
}

# export the public function
Export-ModuleMember -Function ribosome
Write-Verbose "Exported function ribosome"
