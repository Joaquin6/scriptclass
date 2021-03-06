# Copyright 2019, Adam Edwards
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$thismodule = join-path (split-path -parent $here) '../scriptclass.psd1'

Describe 'Unmock-ScriptClassMethodMock cmdlet' {
    BeforeAll {
        remove-module $thismodule -force -erroraction ignore
        import-module $thismodule -force
    }

    AfterAll {
        remove-module $thismodule -force -erroraction ignore
    }

    Context 'Removing mocks for instance methods' {
        It "Should return the mocked value after mocking and then the original value after the mock is removed from the class" {
            ScriptClass TestClassInstanceMethod3 {
                $data = 9
                function RealMethod($parameter1, $parameter2) {
                    $this.data + $parameter1 + $parameter2
                }
            }

            $oldclass = new-so TestClassInstanceMethod3
            $oldclass |=> RealMethod | out-null
            ($oldClass.psobject.methods | where name -eq RealMethod).script.module

            Mock-ScriptClassMethod TestClassInstanceMethod3 RealMethod { 5 }

            $testClass = new-so TestClassInstanceMethod3

            ($testClass |=> RealMethod 3 7) | Should Be 5

            Unmock-ScriptClassMethod TestClassInstanceMethod3 RealMethod

            ($testClass |=> RealMethod 3 7) | Should Be 19
        }
    }

    Context 'Removing mocks for static methods' {
        It "Should return the original value after it was mocked and the mock was removed and return a mocked value" {
            ScriptClass TestClassStaticMethod2 {
                static {
                    $staticdata = 11

                    function StaticRealMethod($parameter1, $parameter2) {
                        $this.staticdata + $parameter1 * $parameter2
                    }
                }
            }

            ($::.TestClassStaticMethod2 |=> StaticRealMethod 3 7) | Should Be ( $::.TestClassStaticMethod2.staticdata + 3 * 7 )

            Mock-ScriptClassMethod TestClassStaticMethod2 StaticRealMethod { 3 } -static

            ($::.TestClassStaticMethod2 |=> StaticRealMethod 3 7) | Should Be 3

            Unmock-ScriptClassMethod TestClassStaticMethod2 StaticRealMethod -static

            ($::.TestClassStaticMethod2 |=> StaticRealMethod 3 7) | Should Be ( $::.TestClassStaticMethod2.staticdata + 3 * 7 )
        }
    }

    Context 'Removing mocks for object methods' {
        It "Should return the mocked value instead of the original after the mock is removed from the object with Remove-ScriptClassMethodMock" {
            ScriptClass TestClassObjectMethod3 {
                $objectdata = 29

                function RealObjectMethod($parameter1, $parameter2) {
                    $this.objectdata + $parameter1 * $parameter2 + 1
                }
            }

            $testObject = new-so TestClassObjectMethod3

            ($testObject |=> RealObjectMethod 3 7) | Should Be ( $testObject.objectData + 3 * 7  + 1 )

            Mock-ScriptClassMethod $testObject RealObjectMethod { 2 }

            ($testObject |=> RealObjectMethod 3 7) | Should Be 2

            Unmock-ScriptClassMethod $testObject RealObjectMethod

            ($testObject |=> RealObjectMethod 3 7) | Should Be ( $testObject.objectData + 3 * 7  + 1 )
        }

        It "Should not remove the mock for an object method if the class is mocked, then the object, and then the instance method mock is removed" {
            ScriptClass TestClassObjectMethod4 {
                $objectdata = 31

                function RealObjectMethod($parameter1, $parameter2) {
                    $this.objectdata + $parameter1 * $parameter2 + 3
                }
            }

            $testObject = new-so TestClassObjectMethod4

            ($testObject |=> RealObjectMethod 3 7) | Should Be ( $testObject.objectData + 3 * 7  + 3 )

            Mock-ScriptClassMethod TestClassObjectMethod4 RealObjectMethod { 2 }

            ($testObject |=> RealObjectMethod 3 7) | Should Be 2

            Mock-ScriptClassMethod $testObject RealObjectMethod { 5 }

            ($testObject |=> RealObjectMethod 3 7) | Should Be 5

            Unmock-ScriptClassMethod TestClassObjectMethod4 RealObjectMethod

            ($testObject |=> RealObjectMethod 3 7) | Should Be 5

            Unmock-ScriptClassMethod $testObject RealObjectMethod

            ($testObject |=> RealObjectMethod 3 7) | Should Be ( $testObject.objectData + 3 * 7  + 3 )
        }

        It "Should not remove the mock for an object method if the object is mocked, then the class, and then the instance method mock is removed" {
            ScriptClass TestClassObjectMethod5 {
                $objectdata = 37

                function RealObjectMethod($parameter1, $parameter2) {
                    $this.objectdata + $parameter1 * $parameter2 + 3
                }
            }

            $testObject = new-so TestClassObjectMethod5

            ($testObject |=> RealObjectMethod 3 7) | Should Be ( $testObject.objectData + 3 * 7  + 3 )

            Mock-ScriptClassMethod $testObject RealObjectMethod { 5 }

            ($testObject |=> RealObjectMethod 3 7) | Should Be 5

            Mock-ScriptClassMethod TestClassObjectMethod5 RealObjectMethod { 2 }


            ($testObject |=> RealObjectMethod 3 7) | Should Be 5

            Unmock-ScriptClassMethod TestClassObjectMethod5 RealObjectMethod


            ($testObject |=> RealObjectMethod 3 7) | Should Be 5

            Unmock-ScriptClassMethod $testObject RealObjectMethod

            ($testObject |=> RealObjectMethod 3 7) | Should Be ( $testObject.objectData + 3 * 7  + 3 )
        }
    }
}

